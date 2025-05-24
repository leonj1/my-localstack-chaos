#!/bin/bash

# Helper script to run Terraform commands with Docker

display_help() {
  echo "Usage: ./run-terraform.sh [command]"
  echo ""
  echo "Commands:"
  echo "  apply       Run terraform init and apply with LocalStack"
  echo "  destroy     Run terraform destroy with LocalStack"
  echo "  plan        Run terraform plan with LocalStack"
  echo "  output      Show terraform outputs"
  echo "  console     Start an interactive Terraform console"
  echo "  custom      Run a custom Terraform command (specify after --)"
  echo ""
  echo "Examples:"
  echo "  ./run-terraform.sh apply"
  echo "  ./run-terraform.sh destroy"
  echo "  ./run-terraform.sh custom -- state list"
  echo ""
}

check_localstack_token() {
  if [ -z "${LOCALSTACK_AUTH_TOKEN}" ]; then
    echo "Error: LOCALSTACK_AUTH_TOKEN environment variable is not set."
    echo "Please set it with: export LOCALSTACK_AUTH_TOKEN=your-token"
    exit 1
  fi
}

ensure_services_running() {
  if ! docker ps | grep -q localstack-pro; then
    echo "Starting LocalStack and Terraform services..."
    docker-compose up -d
    echo "Waiting for services to be ready..."
    
    # Wait for LocalStack to be ready
    for i in $(seq 1 30); do
      if curl -s http://localhost:4666/health | grep -q "\"s3\""; then
        echo "LocalStack is ready!"
        break
      fi
      if [ $i -eq 30 ]; then
        echo "Error: LocalStack did not become ready in time"
        exit 1
      fi
      echo "Waiting for LocalStack to be ready... ($i/30)"
      sleep 2
    done
  fi
}

run_terraform_command() {
  case "$1" in
    apply)
      docker-compose run --rm terraform apply-localstack
      ;;
    destroy)
      docker-compose run --rm terraform destroy-localstack
      ;;
    plan)
      docker-compose run --rm terraform init
      docker-compose run --rm terraform plan
      ;;
    output)
      docker-compose run --rm terraform output
      ;;
    console)
      docker-compose run --rm terraform console
      ;;
    custom)
      shift
      if [ "$1" = "--" ]; then
        shift
        docker-compose run --rm terraform "$@"
      else
        echo "Error: Please use -- to separate custom commands"
        display_help
        exit 1
      fi
      ;;
    *)
      display_help
      exit 1
      ;;
  esac
}

# Main execution
main() {
  if [ $# -eq 0 ]; then
    display_help
    exit 0
  fi
  
  check_localstack_token
  ensure_services_running
  run_terraform_command "$@"
}

main "$@"
