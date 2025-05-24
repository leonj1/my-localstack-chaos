# LocalStack Pro with Terraform ECS Deployment

This project uses LocalStack Pro to emulate AWS services locally for development and testing. It includes a Terraform configuration for deploying a Hello World Nginx server on ECS across multiple regions with Route53 latency-based routing.

## Prerequisites

- Docker and Docker Compose installed
- LocalStack Pro authentication token

## Setup

1. Set your LocalStack Pro authentication token as an environment variable:

```bash
export LOCALSTACK_AUTH_TOKEN=your-localstack-pro-token
```

2. Start the LocalStack Pro and Terraform containers:

```bash
docker-compose up -d
```

3. Verify LocalStack is running:

```bash
curl http://localhost:4566/health
```

## Using the Makefile

The project includes a Makefile to simplify common operations:

```bash
# Start LocalStack and apply Terraform configuration
make start

# Stop all services
make stop

# Restart all services (stop and start)
make restart

# Show Terraform outputs
make outputs

# Plan Terraform changes
make plan

# Apply Terraform changes only
make apply

# Destroy infrastructure
make destroy

# Clean up everything (stop services and remove volumes)
make clean

# Show help
make help
```

## Running Terraform with Docker

The project includes a Dockerfile.terraform that packages the Terraform CLI with all necessary tools to apply configurations to LocalStack.

### Apply Terraform Configuration

```bash
docker-compose run terraform apply-localstack
```

This will:
1. Wait for LocalStack to be ready
2. Configure Terraform providers for LocalStack
3. Run `terraform init` and `terraform apply -auto-approve`

### Destroy Infrastructure

```bash
docker-compose run terraform destroy-localstack
```

### Run Custom Terraform Commands

```bash
docker-compose run terraform [command]
```

For example:
```bash
docker-compose run terraform plan
```

## Terraform Configuration

The Terraform setup includes:

- ECS clusters in us-east-1 and us-west-1 regions
- Nginx containers with region-specific "Hello World" messages
- Route53 configuration with latency-based routing
- Region-specific DNS entries

## Docker Compose Services

- **localstack**: LocalStack Pro running on port 4566
- **terraform**: Terraform CLI configured to work with LocalStack

## Stopping the Services

```bash
docker-compose down
```
