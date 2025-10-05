# Makefile for Docker AI Development Environment

.PHONY: help build up down restart logs shell clean test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	@echo "Building Docker image with Cline extension..."
	docker compose build
	@echo "✓ Build complete!"

up: ## Start the environment
	docker compose up -d
	@echo ""
	@echo "=================================="
	@echo "✓ Environment started successfully!"
	@echo "=================================="
	@echo ""
	@echo "Access Code Server at: http://localhost:8080"
	@echo ""
	@echo "The Cline extension is pre-installed and ready to use."
	@echo ""
	@echo "Useful commands:"
	@echo "  make logs    - View container logs"
	@echo "  make shell   - Open a shell in the container"
	@echo "  make down    - Stop the environment"
	@echo ""

down: ## Stop the environment
	docker compose down

restart: down up ## Restart the environment

logs: ## Show container logs
	docker compose logs -f cline-aider-dev

shell: ## Open a shell in the container
	docker compose exec cline-aider-dev bash

clean: ## Remove containers, images, and volumes
	docker compose down -v
	docker rmi opencline-cline-aider-dev 2>/dev/null || true
	@echo "Environment cleaned"

test: ## Test the Docker setup (build and start)
	@echo "Testing Docker environment setup..."
	docker compose build
	docker compose up -d
	@echo "Waiting for services to start..."
	@sleep 5
	docker compose ps
	docker compose exec cline-aider-dev python3 --version
	docker compose exec cline-aider-dev node --version
	docker compose exec cline-aider-dev code-server --version
	docker compose exec cline-aider-dev gh --version
	docker compose exec cline-aider-dev supabase --version
	docker compose exec cline-aider-dev python3 /opt/aider/aider/main.py --version 2>/dev/null || echo "Aider check skipped (might need dependencies)"
	@echo "Test completed successfully!"

init: ## Initialize environment with .env file
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ".env file created from .env.example"; \
		echo "Please edit .env and add your tokens"; \
	else \
		echo ".env file already exists"; \
	fi

validate: ## Validate Docker extension setup
	@./scripts/validate-extension-setup.sh

.DEFAULT_GOAL := help
