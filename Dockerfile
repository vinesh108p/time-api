FROM --platform=linux/amd64 golang:1.22.4-alpine3.19

# Add Maintainer Info
LABEL maintainer="Vinesh Patel <vinesh108p@gmail.com>"

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy everything from the current directory to the Working Directory inside the container
COPY . .

# Build the Go app
ENV GO111MODULE=auto
RUN GOOS=linux GOARCH=amd64 go build -o main .

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./main"]