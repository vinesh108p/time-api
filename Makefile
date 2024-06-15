## Local Development

run-locally: # Run the API server locally
	GO111MODULE=auto go run main.go

test-locally: # Test the API endpoint on the local server.
	curl -f http://localhost:8080/time_in_epoch