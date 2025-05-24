#!/bin/bash

# Enable LocalStack configuration in Terraform providers
setup_localstack_providers() {
  echo "Configuring Terraform providers for LocalStack..."
  sed -i 's/# skip_credentials_validation/skip_credentials_validation/g' providers.tf
  sed -i 's/# skip_metadata_api_check/skip_metadata_api_check/g' providers.tf
  sed -i 's/# skip_requesting_account_id/skip_requesting_account_id/g' providers.tf
  sed -i 's/# access_key/access_key/g' providers.tf
  sed -i 's/# secret_key/secret_key/g' providers.tf
  sed -i 's/# endpoints {/endpoints {/g' providers.tf
  sed -i 's/#   /  /g' providers.tf
  sed -i 's/# }/}/g' providers.tf
}

# Check if LocalStack is running
check_localstack() {
  echo "Checking if LocalStack is running..."
  if curl -s http://localhost:4666/health > /dev/null; then
    echo "LocalStack is running"
    return 0
  else
    echo "LocalStack is not running. Please start it first with:"
    echo "cd .. && docker-compose up -d"
    return 1
  fi
}

# Main execution
main() {
  if ! check_localstack; then
    exit 1
  fi
  
  setup_localstack_providers
  
  echo "Creating terraform.tfvars file..."
  cat > terraform.tfvars << EOF
environment = "dev"
app_name = "nginx-hello-world"
app_count = 1
container_image = "nginx:latest"
container_port = 80
domain_name = "example.local"
EOF
  
  echo "Initializing Terraform..."
  terraform init
  
  echo "Setup complete! You can now run:"
  echo "terraform plan"
  echo "terraform apply"
}

main
