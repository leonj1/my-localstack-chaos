.PHONY: all-up help localstack-up localstack-down tf-init tf-up tf-down tf-plan build-tf-image build-integration-image integration chaos-test chaos-test-quick chaos-test-scenario-a chaos-test-scenario-b chaos-setup

all-up: localstack-up tf-init tf-up

help:
	@echo "Available targets:"
	@echo "  localstack-up    - Start LocalStack container"
	@echo "  localstack-down  - Stop LocalStack container"
	@echo "  tf-init          - Initialize Terraform"
	@echo "  tf-plan          - Plan Terraform changes"
	@echo "  tf-up            - Apply Terraform configuration to create resources"
	@echo "  tf-down          - Destroy Terraform resources"
	@echo "  all-up           - Start LocalStack and apply Terraform"
	@echo "  all-down         - Destroy Terraform resources and stop LocalStack"
	@echo "  build-integration-image - Build the integration test Docker image"
	@echo "  integration      - Run the integration tests against LocalStack"
	@echo "  chaos-setup      - Install Python dependencies for chaos testing"
	@echo "  chaos-test       - Run full chaos engineering test suite (requires LocalStack running)"
	@echo "  chaos-test-quick - Run quick health check only (requires LocalStack running)"
	@echo "  chaos-test-scenario-a - Test us-east-1 failure scenario (requires LocalStack running)"
	@echo "  chaos-test-scenario-b - Test us-west-1 failure scenario (requires LocalStack running)"
	@echo "  chaos-test-full-workflow - Complete workflow: start LocalStack, deploy infrastructure, run chaos tests"

localstack-up:
	docker-compose up -d

localstack-down:
	docker-compose down

build-tf-image:
	docker build -t terraform-local -f Dockerfile.terraform .

tf-init: build-tf-image
	docker run --rm -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network -e USE_LOCALSTACK=true terraform-local init

tf-plan: build-tf-image
	docker run --rm -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network -e USE_LOCALSTACK=true terraform-local plan -var="is_localstack=true"

tf-up: build-tf-image
	docker run --rm -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network -e USE_LOCALSTACK=true terraform-local apply-localstack -var="is_localstack=true"

tf-down: build-tf-image
	docker run --rm -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network -e USE_LOCALSTACK=true terraform-local destroy -auto-approve -var="is_localstack=true"

all-down: tf-down localstack-down

# Chaos Engineering Test Targets
chaos-setup:
	@echo "Installing Python dependencies for chaos testing..."
	pip3 install -r requirements.txt
	@echo "Setting up AWS CLI configuration for LocalStack..."
	aws configure set aws_access_key_id test
	aws configure set aws_secret_access_key test
	aws configure set region us-east-1
	@echo "Chaos testing setup complete!"

chaos-test: chaos-setup
	@echo "Checking if LocalStack is running..."
	@if ! curl -s http://172.17.0.1:4666/_localstack/health > /dev/null 2>&1; then \
		echo "❌ LocalStack is not running. Please start it first with 'make localstack-up'"; \
		echo "   Then deploy infrastructure with 'make tf-up'"; \
		exit 1; \
	fi
	@echo "✅ LocalStack is running"
	@echo "Running full chaos engineering test suite..."
	python3 chaos_test.py --full-test

chaos-test-quick: chaos-setup
	@echo "Checking if LocalStack is running..."
	@if ! curl -s http://172.17.0.1:4666/_localstack/health > /dev/null 2>&1; then \
		echo "❌ LocalStack is not running. Please start it first with 'make localstack-up'"; \
		exit 1; \
	fi
	@echo "✅ LocalStack is running"
	@echo "Running quick health check..."
	python3 chaos_test.py --quick

chaos-test-scenario-a: chaos-setup
	@echo "Checking if LocalStack is running..."
	@if ! curl -s http://172.17.0.1:4666/_localstack/health > /dev/null 2>&1; then \
		echo "❌ LocalStack is not running. Please start it first with 'make localstack-up'"; \
		echo "   Then deploy infrastructure with 'make tf-up'"; \
		exit 1; \
	fi
	@echo "✅ LocalStack is running"
	@echo "Testing us-east-1 failure scenario..."
	python3 chaos_test.py --scenario=us-east-1

chaos-test-scenario-b: chaos-setup
	@echo "Checking if LocalStack is running..."
	@if ! curl -s http://172.17.0.1:4666/_localstack/health > /dev/null 2>&1; then \
		echo "❌ LocalStack is not running. Please start it first with 'make localstack-up'"; \
		echo "   Then deploy infrastructure with 'make tf-up'"; \
		exit 1; \
	fi
	@echo "✅ LocalStack is running"
	@echo "Testing us-west-1 failure scenario..."
	python3 chaos_test.py --scenario=us-west-1

# Complete workflow target that sets up everything
chaos-test-full-workflow: localstack-up tf-up chaos-test
	@echo "🎉 Complete chaos engineering workflow completed!"
