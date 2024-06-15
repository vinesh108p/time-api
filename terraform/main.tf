provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  region        = "us-west-1"
  name          = "time-api"
  environment   = "test"
  ecr_repo_name = "time-api"

  vpc_cidr = "172.12.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  container_name_epoch_time  = "epoch-time"
  container_port             = 8080
  container_image_epoch_time = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.ecr_repo_name}:latest"

  tags = {
    Name        = local.name
    Production  = "false"
    Environment = local.environment
    Accounting  = "engineering.infrastructure.nonprod"
  }
}

################################################################################
# ECS Cluster
################################################################################

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.2"

  cluster_name = local.name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    time-api = {
      cpu    = 512
      memory = 1024
      container_definitions = {

        epoch-time = {
          cpu       = 256
          memory    = 512
          essential = true
          image     = local.container_image_epoch_time

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/time_in_epoch || exit 1"]
          }

          port_mappings = [
            {
              name          = local.container_name_epoch_time
              containerPort = local.container_port
              hostPort      = local.container_port
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false
          memory_reservation       = 100
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["epoch-time"].arn
          container_name   = local.container_name_epoch_time
          container_port   = local.container_port
        }
      }

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_8080 = {
          type                     = "ingress"
          from_port                = local.container_port
          to_port                  = local.container_port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Load Balancer
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Only because this is not really going into production
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "epoch-time"
      }
    }
  }

  target_groups = {
    epoch-time = {
      name                              = local.container_name_epoch_time
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/time_in_epoch"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # Theres nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = local.tags
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}