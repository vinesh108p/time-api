# Description
This API server exposes an endpoint which provides the Epoch time.

#### Request:

```http
GET /time_in_epoch
```

#### Response:

```json
{"The current epoch time":1718473309}
```

# Dependencies
* AWS CLI - 2.16.8
* Docker - 20.10.12
* GNU Make - 3.81
* Terraform - 1.8.5

Provided versions are known tested versions.

# How to Deploy the API server
## AWS Deployment
### Prerequisites
* Ensure [dependenices](#dependencies) listed above are installed.

* Prepare your AWS credentials and configure them on your machine. You can verify if the credentials are working and you are authenticated to the desired user/role by running the command: `make aws-validate`

* Ensure Docker is running

### First time Build & Deploy
If you do not have a current environment built out in an AWS region, you can easily create an environment by running the command numbered 1 below.

Should you need to delete the environment and clean up all resources including locally created artifacts, run the command numbered 2 below.

1. `make initialise-service`

2. `make destroy-service`

### Notes:
* When creating the service for the first time, please wait a few minutes for the container to run. Alternatively, you can check the [AWS console](https://us-west-1.console.aws.amazon.com/ecs/v2/clusters/time-api/services/time-api/tasks?region=us-west-1) to see the status. The link to the console will work provided no changes are made to the terraform configuration.

* After terraform apply runs, the output will provide a command that can be used to test the API endpoint using cURL.

* If changes are made to `region` and `ecr_repo_name` in the main.tf file then please make the same changes in the Makefile for `AWS_REGION` and `IMG_NAME` respectively. Failure to make these changes will result in resources not being provisioned correctly and thus the application will not run.

## Local Development

To run the server locally, use the Make command `make run-locally` and once the server is running, test the endpoint with `make test-locally`

# Useful commands
The following Make commands can be useful as part of the developement and deployment process.

Build Docker images:
    `make docker-build`

Push images to ECR: 
    `make docker-push`

Create an ECR repository, if you do not already have one:
    `make ecr-repo-create`

Run Terraform Plan:
    `make terraform-plan`

Run Terraform Apply:
    `make terraform-apply`

Destroy all AWS resources:
    `make terraform-destroy`