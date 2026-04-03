BINARY_NAME=vlab

.PHONY: all build test clean tidy

all: tidy test build

tidy:
	go mod tidy

test:
	go test -v ./...

build:
	go build -o bin/$(BINARY_NAME) ./cmd/vlab

clean:
	rm -rf bin/
	rm -rf dist/
