# LocalStack Pro with Docker Compose

This project uses LocalStack Pro to emulate AWS services locally for development and testing.

## Prerequisites

- Docker and Docker Compose installed
- LocalStack Pro authentication token

## Setup

1. Set your LocalStack Pro authentication token as an environment variable:

```bash
export LOCALSTACK_AUTH_TOKEN=your-localstack-pro-token
```

2. Start the LocalStack Pro container:

```bash
docker-compose up -d
```

3. Verify LocalStack is running:

```bash
curl http://localhost:4566/health
```

## Configuration

The Docker Compose setup includes:

- LocalStack Pro running on port 4566
- External services on ports 4510-4559
- Volume mapping for persistent data
- Docker socket access for container-in-container functionality

## Stopping the Services

```bash
docker-compose down
```
