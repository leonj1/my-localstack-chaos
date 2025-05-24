.PHONY: help localstack-up localstack-down tf-init tf-up tf-down tf-plan build-tf-image build-integration-image integration

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

localstack-up:
	docker-compose up -d

localstack-down:
	docker-compose down

build-tf-image:
	docker build -t terraform-local -f Dockerfile.terraform .

tf-init: build-tf-image
	docker run --rm -v $(PWD)/terraform:/terraform -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network terraform-local init

tf-plan: build-tf-image
	docker run --rm -v $(PWD)/terraform:/terraform -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network terraform-local plan -var="is_localstack=true"

tf-up: build-tf-image
	docker run --rm -v $(PWD)/terraform:/terraform -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network terraform-local apply -auto-approve -var="is_localstack=true"

tf-down: build-tf-image
	docker run --rm -v $(PWD)/terraform:/terraform -v $(HOME)/.aws:/root/.aws --network my-localstack-chaos_localstack-network terraform-local destroy -auto-approve -var="is_localstack=true"

all-up: localstack-up tf-init tf-up

all-down: tf-down localstack-down

