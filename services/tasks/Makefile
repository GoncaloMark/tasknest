BIN_DIR := bin
BINARY_NAME := tasks

PROD_GO_FLAGS := -ldflags "-s -w" -o $(BIN_DIR)/$(BINARY_NAME)
DEV_GO_FLAGS := -o $(BIN_DIR)/$(BINARY_NAME)

.PHONY: deps fmt clean build prod all

deps:
	@go mod tidy

fmt:
	@go fmt ./...

build:
	@mkdir -p $(BIN_DIR)
	@go build $(DEV_GO_FLAGS) .

prod:
	@mkdir -p $(BIN_DIR)
	@go build $(PROD_GO_FLAGS) .

clean:
	@rm -rf $(BIN_DIR)

all: deps fmt build
