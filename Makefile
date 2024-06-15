# Variables
IMG_NAME = time-api
AWS_REGION = us-west-1
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
REV := $(shell git rev-parse HEAD | cut -c1-7)
REG := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
REPO := $(REG)/$(IMG_NAME)

## Build

docker-build: # Build and tag docker image
	docker build -f Dockerfile --no-cache -t $(IMG_NAME):latest .

docker-push: ecr-login # Push docker image
	docker tag $(IMG_NAME):latest $(REPO):latest
	docker tag $(IMG_NAME):latest $(REPO):$(REV)
	docker push $(REPO):latest
	docker push $(REPO):$(REV)

docker-delete-local: # Delete all local images
	docker images --filter=reference='$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(IMG_NAME)' --format "{{.ID}}" | xargs -r docker rmi -f

## ECR things

ecr-repo-create: # Create ECR repo
	aws ecr create-repository --repository-name $(IMG_NAME) --region $(AWS_REGION)

ecr-repo-delete: # Delete ECR Repo
	aws ecr delete-repository --repository-name $(IMG_NAME) --force --region $(AWS_REGION)

ecr-login: # Login to ECR
	aws ecr get-login-password --region $(AWS_REGION) | docker login --password-stdin --username AWS $(REG)

## Terraform

terraform-plan: # Run terraform plan to see changes
	terraform -chdir=terraform init && terraform -chdir=terraform plan

terraform-apply: # Run terraform apply to make changes
	terraform -chdir=terraform init && terraform -chdir=terraform apply -auto-approve

terraform-destroy: # Run terraform destroy to delete all cloud resources
	terraform -chdir=terraform init && terraform -chdir=terraform destroy -auto-approve

## AWS stuff

aws-validate: # Validate AWS credentials to ensure correct user/role is being used
	aws sts get-caller-identity

## Local Development

run-locally: # Run the API server locally
	GO111MODULE=auto go run main.go

test-locally: # Test the API endpoint on the local server.
	curl -f http://localhost:8080/time_in_epoch

## Combinations for workflows

# Used to build docker images and make infra changes. Assumes ECR repo exists already.
build-and-deploy: docker-build ecr-login docker-push terraform-apply

# Used to build the docker image and all AWS resources. Assumes ECR repo does NOT exist.
initialise-service: docker-build ecr-repo-create ecr-login docker-push terraform-apply

 # Used to delete all artifacts locally and remotely while deleting all AWS resources, including ECR repo.
destroy-service: terraform-destroy ecr-repo-delete docker-delete-local