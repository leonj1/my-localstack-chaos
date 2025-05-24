#!/bin/bash

# Post-create script for LocalStack Chaos Engineering devcontainer
echo "🚀 Setting up LocalStack Chaos Engineering development environment..."

# Update package lists
sudo apt-get update

# Install additional useful tools
echo "📦 Installing additional tools..."
sudo apt-get install -y \
    curl \
    wget \
    jq \
    tree \
    htop \
    vim \
    git \
    make \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release

# Install LocalStack CLI
echo "🏗️ Installing LocalStack CLI..."
pip3 install --user localstack

# Add LocalStack CLI to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Install tfenv for Terraform version management (optional)
echo "🔧 Installing tfenv for Terraform version management..."
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc

# Install Python development dependencies
echo "🐍 Installing Python development tools..."
pip3 install --user \
    boto3 \
    pytest \
    black \
    pylint \
    flake8 \
    mypy \
    requests

# Set up Docker socket permissions
echo "🐳 Setting up Docker permissions..."
sudo chmod 666 /var/run/docker-host.sock
sudo ln -sf /var/run/docker-host.sock /var/run/docker.sock

# Create useful aliases
echo "⚡ Setting up useful aliases..."
cat >> ~/.bashrc << 'EOF'

# LocalStack aliases
alias ls-start='make localstack-up'
alias ls-stop='make localstack-down'
alias ls-status='curl -s http://localhost:4566/health | jq'
alias ls-logs='docker logs localstack-pro'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# Docker aliases
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'

# General aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# quality of life
alias gs="git status"
alias gb="git branch"
EOF

# Create a welcome message
cat > ~/.welcome << 'EOF'
🎉 Welcome to LocalStack Chaos Engineering Development Environment!

Available tools:
- Python 3.13 with development packages
- Docker & Docker Compose
- Terraform with latest version
- AWS CLI configured for LocalStack
- LocalStack CLI
- Various development tools (jq, curl, git, etc.)

Quick start:
1. Set your LocalStack Pro token: export LOCALSTACK_AUTH_TOKEN=your-token
2. Start LocalStack: make localstack-up
3. Initialize Terraform: make tf-init
4. Apply infrastructure: make tf-up

Useful commands:
- make help          # Show available make targets
- ls-status          # Check LocalStack health
- docker ps          # List running containers
- terraform --help   # Terraform help

Happy coding! 🚀
EOF

# Add welcome message to bashrc
echo 'cat ~/.welcome' >> ~/.bashrc

# Make the script executable
chmod +x ~/.bashrc

# Create a .env file template if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env template..."
    cp .env.example .env 2>/dev/null || echo "# LocalStack Configuration
LOCALSTACK_AUTH_TOKEN=your-localstack-pro-token-here
LOCALSTACK_VOLUME_DIR=./volume
TF_LOG=INFO" > .env
fi

# Set proper permissions for the project
sudo chown -R vscode:vscode /workspaces/

echo "✅ Development environment setup complete!"
echo "🔄 Please reload your terminal or run 'source ~/.bashrc' to apply changes."
