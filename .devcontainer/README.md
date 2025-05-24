# DevContainer for LocalStack Chaos Engineering

This devcontainer provides a complete development environment for the LocalStack Chaos Engineering project with all necessary tools pre-installed and configured.

## What's Included

### Core Tools
- **Python 3.13** - Latest Python version with development packages
- **Docker & Docker Compose** - Container orchestration tools
- **Terraform** - Infrastructure as Code tool with latest version
- **AWS CLI** - Command line interface for AWS services
- **LocalStack CLI** - Command line interface for LocalStack

### Development Tools
- **Git** - Version control
- **Make** - Build automation
- **jq** - JSON processor
- **curl/wget** - HTTP clients
- **vim** - Text editor
- **tree** - Directory structure viewer
- **htop** - Process viewer

### Python Packages
- **boto3** - AWS SDK for Python
- **pytest** - Testing framework
- **black** - Code formatter
- **pylint** - Code linter
- **flake8** - Style guide enforcement
- **mypy** - Static type checker
- **requests** - HTTP library

### VS Code Extensions
- HashiCorp Terraform
- Docker
- Python
- Python Linting (Pylint)
- Python Formatting (Black)
- YAML
- Makefile Tools
- AWS Toolkit

## Getting Started

### Prerequisites
- VS Code with the Dev Containers extension
- Docker Desktop running on your machine

### Opening the DevContainer

1. Clone this repository
2. Open the folder in VS Code
3. When prompted, click "Reopen in Container" or use the Command Palette:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Reopen in Container"
   - Press Enter

### First Time Setup

1. **Set your LocalStack Pro token:**
   ```bash
   export LOCALSTACK_AUTH_TOKEN=your-localstack-pro-token-here
   ```
   
2. **Start LocalStack:**
   ```bash
   make localstack-up
   ```

3. **Initialize Terraform:**
   ```bash
   make tf-init
   ```

4. **Apply the infrastructure:**
   ```bash
   make tf-up
   ```

## Useful Aliases

The devcontainer comes with pre-configured aliases to speed up development:

### LocalStack Aliases
- `ls-start` - Start LocalStack (`make localstack-up`)
- `ls-stop` - Stop LocalStack (`make localstack-down`)
- `ls-status` - Check LocalStack health
- `ls-logs` - View LocalStack logs

### Terraform Aliases
- `tf` - Terraform command
- `tfi` - Terraform init
- `tfp` - Terraform plan
- `tfa` - Terraform apply
- `tfd` - Terraform destroy

### Docker Aliases
- `dc` - Docker Compose command
- `dcu` - Docker Compose up -d
- `dcd` - Docker Compose down
- `dcl` - Docker Compose logs

### General Aliases
- `ll` - List files in long format
- `la` - List all files
- `l` - List files
- `..` - Go up one directory
- `...` - Go up two directories

## Port Forwarding

The devcontainer automatically forwards these ports:
- **4566** - LocalStack main port
- **4666** - LocalStack Pro port (mapped from 4566 in docker-compose)

## Environment Variables

The following environment variables are pre-configured:
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`
- `AWS_DEFAULT_REGION=us-east-1`
- `LOCALSTACK_HOST=localhost`
- `LOCALSTACK_PORT=4566`
- `TF_LOG=INFO`

## File Structure

```
.devcontainer/
├── devcontainer.json    # Main devcontainer configuration
├── post-create.sh       # Setup script run after container creation
└── README.md           # This file
```

## Troubleshooting

### Docker Socket Issues
If you encounter Docker socket permission issues:
```bash
sudo chmod 666 /var/run/docker.sock
```

### LocalStack Connection Issues
Ensure LocalStack is running and accessible:
```bash
ls-status
```

### Terraform Issues
If Terraform commands fail, ensure you're in the correct directory and LocalStack is running:
```bash
cd terraform
terraform init
```

### Python Package Issues
If Python packages are missing, reinstall them:
```bash
pip3 install --user boto3 pytest black pylint flake8 mypy requests
```

## Customization

### Adding More Tools
Edit `.devcontainer/post-create.sh` to install additional tools.

### Adding VS Code Extensions
Edit the `extensions` array in `.devcontainer/devcontainer.json`.

### Changing Environment Variables
Edit the `containerEnv` section in `.devcontainer/devcontainer.json`.

## Performance Tips

1. **Use Docker volumes** for better performance with large codebases
2. **Exclude node_modules** and other large directories from file watching
3. **Use .dockerignore** to exclude unnecessary files from the build context

## Support

If you encounter issues with the devcontainer:
1. Check the VS Code Dev Containers documentation
2. Verify Docker Desktop is running
3. Try rebuilding the container: "Dev Containers: Rebuild Container"
4. Check the container logs for error messages
