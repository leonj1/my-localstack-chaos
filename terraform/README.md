# Terraform ECS Nginx Hello World

This Terraform configuration deploys a Hello World Nginx server onto ECS services across both us-east-1 and us-west-1 regions with Route53 DNS configuration for latency-based routing.

## Architecture

- Creates a VPC with public and private subnets in each region
- Sets up NAT Gateways for outbound connectivity from private subnets
- Deploys an Application Load Balancer (ALB) in each region
- Creates ECS Fargate clusters in each region
- Runs Nginx containers with region-specific "Hello World" messages
- Configures security groups, IAM roles, and CloudWatch logging
- Sets up Route53 with latency-based routing across regions
- Creates region-specific DNS entries for direct access to each region

## Prerequisites

- Terraform installed (v1.0.0+)
- AWS CLI configured with appropriate credentials
- Docker (if you want to build and push the custom Nginx image)

## Usage with LocalStack

This project can be used with LocalStack for local development and testing:

1. Start LocalStack using the Docker Compose configuration in the project root:

```bash
cd ..
export LOCALSTACK_AUTH_TOKEN=your-localstack-pro-token
docker-compose up -d
```

2. Configure Terraform to use LocalStack by creating a `terraform.tfvars` file:

```bash
cd terraform
```

3. Initialize Terraform with LocalStack provider:

```bash
terraform init
```

4. Apply the Terraform configuration:

```bash
terraform apply
```

## Customization

You can customize the deployment by modifying the variables in `variables.tf` or by providing a `terraform.tfvars` file with your own values.

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```
