# Variables
IMG_NAME = time-api

## Build

docker-build: # Build and tag docker image
	docker build -f Dockerfile --no-cache -t $(IMG_NAME):latest .

## Local Development

run-locally: # Run the API server locally
	GO111MODULE=auto go run main.go

test-locally: # Test the API endpoint on the local server.
	curl -f http://localhost:8080/time_in_epoch