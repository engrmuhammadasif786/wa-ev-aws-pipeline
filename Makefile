.PHONY: help up down test lint format deploy run-aws dashboard clean

COMPOSE_CMD = docker compose --env-file .env -f docker/docker-compose.yml

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start local Airflow + Streamlit with Docker Compose
	@echo "Starting local environment..."
	export AIRFLOW_UID=$$(id -u) && $(COMPOSE_CMD) up -d --build
	@echo "Airflow UI: http://localhost:8080 (user: airflow, pass: airflow)"
	@echo "Streamlit:  http://localhost:8501"

down: ## Stop local environment
	@echo "Stopping local environment..."
	$(COMPOSE_CMD) down

test: ## Run Python tests
	@echo "Running tests..."
	pytest tests/ -v

lint: ## Lint Python code with Ruff
	@echo "Linting..."
	ruff check src/ tests/ dags/

format: ## Format Python code with Black
	@echo "Formatting..."
	black src/ tests/ dags/

format-check: ## Check code formatting
	black --check src/ tests/ dags/

build: ## Build Docker image locally
	@echo "Building Docker image..."
	docker build -f docker/Dockerfile -t wa-ev:latest .

deploy: ## Deploy infrastructure with Terraform
	@echo "Deploying to AWS..."
	cd terraform && terraform init && terraform apply

run-aws: ## Trigger Step Functions execution manually
	@echo "Starting Step Functions execution..."
	aws stepfunctions start-execution \
		--state-machine-arn $$(cd terraform && terraform output -raw step_functions_arn) \
		--name manual-$$(date +%s)

dashboard: ## Run Streamlit dashboard locally
	@echo "Starting Streamlit dashboard..."
	streamlit run src/dashboard/streamlit_app.py

clean: ## Remove local Docker volumes and temp files
	@echo "Cleaning up..."
	$(COMPOSE_CMD) down -v
	rm -rf logs/
	rm -rf .pytest_cache/
	rm -rf __pycache__/
