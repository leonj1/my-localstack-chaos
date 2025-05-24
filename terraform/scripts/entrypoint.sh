#!/bin/bash
set -e

# Function to check if LocalStack is ready
check_localstack() {
  echo "Checking if LocalStack is ready..."
  for i in {1..30}; do
    if curl -s "http://${LOCALSTACK_HOST}:${LOCALSTACK_PORT}/health" | grep -q "\"s3\""; then
      echo "LocalStack is ready!"
      return 0
    fi
    echo "Waiting for LocalStack to be ready... ($i/30)"
    sleep 2
  done
  echo "Error: LocalStack did not become ready in time"
  return 1
}

# Function to configure Terraform for LocalStack
configure_terraform() {
  echo "Configuring Terraform for LocalStack..."
  
  # Create a local .terraformrc file to disable signature verification
  cat > ~/.terraformrc << EOF
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yevgeniy.com"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
  
  # Create terraform.tfvars file
  cat > terraform.tfvars << EOF
environment = "dev"
app_name = "nginx-hello-world"
app_count = 1
container_image = "nginx:latest"
container_port = 80
domain_name = "example.local"
EOF

  # Configure providers.tf for LocalStack
  sed -i 's/# skip_credentials_validation/skip_credentials_validation/g' providers.tf
  sed -i 's/# skip_metadata_api_check/skip_metadata_api_check/g' providers.tf
  sed -i 's/# skip_requesting_account_id/skip_requesting_account_id/g' providers.tf
  sed -i 's/# access_key/access_key/g' providers.tf
  sed -i 's/# secret_key/secret_key/g' providers.tf
  sed -i 's/# endpoints {/endpoints {/g' providers.tf
  sed -i 's/#   /  /g' providers.tf
  sed -i 's/# }/}/g' providers.tf
  
  # Update endpoints to use LOCALSTACK_HOST environment variable
  sed -i "s/http:\/\/localhost:4566/http:\/\/${LOCALSTACK_HOST}:${LOCALSTACK_PORT}/g" providers.tf
}

# Main execution
main() {
  # Copy terraform files if mounted
  if [ -d "/terraform-src" ]; then
    echo "Copying terraform files from mounted directory..."
    cp -r /terraform-src/* /terraform/
  fi
  
  # Check if we're running with LocalStack
  if [ "${USE_LOCALSTACK}" = "true" ]; then
    check_localstack
    configure_terraform
  fi
  
  # Execute terraform with the provided arguments
  if [ "$1" = "apply-localstack" ]; then
    echo "Running terraform init and apply for LocalStack..."
    terraform init
    terraform apply -auto-approve
  elif [ "$1" = "destroy-localstack" ]; then
    echo "Running terraform destroy for LocalStack..."
    terraform init
    terraform destroy -auto-approve
  else
    # Run terraform with the provided arguments
    terraform "$@"
  fi
}

main "$@"
