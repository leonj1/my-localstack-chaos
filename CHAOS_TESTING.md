# LocalStack Chaos Engineering Test Suite

This document describes the chaos engineering test suite for validating the resilience of the multi-region web server deployment.

## Overview

The chaos engineering test suite validates that your multi-region LocalStack deployment can handle region failures gracefully. It tests two primary scenarios:

1. **Scenario A**: Disable `us-east-1` region and verify `us-west-1` continues to serve traffic
2. **Scenario B**: Disable `us-west-1` region and verify `us-east-1` continues to serve traffic

## Architecture

The test suite uses the following approach to simulate failures:

- **ECS Service Scaling**: Scales down ECS services to 0 tasks to simulate region failure
- **DNS Testing**: Validates Route53 global and regional endpoints
- **Container Connectivity**: Tests direct access to nginx containers
- **Service Restoration**: Scales services back up and validates recovery

## Prerequisites

1. LocalStack Pro running with chaos engineering plugin enabled
2. Terraform infrastructure deployed (`make all-up`)
3. Python 3.7+ with required dependencies

## Quick Start

### 1. Setup Dependencies
```bash
make chaos-setup
```

### 2. Run Full Test Suite
```bash
make chaos-test
```

### 3. Run Quick Health Check
```bash
make chaos-test-quick
```

### 4. Run Individual Scenarios
```bash
# Test us-east-1 failure
make chaos-test-scenario-a

# Test us-west-1 failure  
make chaos-test-scenario-b
```

## Manual Usage

You can also run the chaos test script directly:

```bash
# Full test suite
python3 chaos_test.py --full-test

# Quick health check only
python3 chaos_test.py --quick

# Single scenario
python3 chaos_test.py --scenario=us-east-1
python3 chaos_test.py --scenario=us-west-1

# Custom output file
python3 chaos_test.py --output=my_results.json
```

## Test Flow

### Initial Health Check
1. Verify LocalStack is running and healthy
2. Test DNS resolution for global and regional endpoints
3. Test direct container connectivity
4. Ensure at least one region is working

### Chaos Injection
1. Scale down ECS service in target region to 0 tasks
2. Wait for changes to take effect (10 seconds)
3. Test connectivity to verify failure

### Resilience Validation
1. Test that the remaining region still serves traffic
2. Verify DNS resolution works for working region
3. Validate container connectivity for working region

### Service Restoration
1. Scale ECS service back up to 2 tasks
2. Wait for service to become healthy (15 seconds)
3. Verify both regions are working again

### Final Health Check
1. Run complete health check again
2. Ensure all services are restored
3. Generate final report

## Configuration

The test suite uses `chaos_config.json` for configuration:

```json
{
  "localstack": {
    "endpoint": "http://localhost:4666",
    "port": 4666
  },
  "regions": ["us-east-1", "us-west-1"],
  "domain": "example.com",
  "services": {
    "ecs": {
      "cluster_name_template": "nginx-hello-world-cluster-{region}",
      "service_name_template": "nginx-hello-world-service-{region}",
      "desired_count": 2
    }
  },
  "timeouts": {
    "health_check": 10,
    "chaos_injection_wait": 10,
    "service_restoration_wait": 15,
    "dns_resolution": 15,
    "container_connectivity": 10
  }
}
```

## Output and Reporting

### Console Output
The test suite provides real-time logging to both console and `chaos_test.log` file.

### JSON Results
Detailed test results are saved to `chaos_test_results.json` (or custom file via `--output`):

```json
{
  "start_time": "2025-05-24T21:00:00",
  "end_time": "2025-05-24T21:05:00", 
  "overall_status": "PASSED",
  "scenarios": {
    "disable_us_east_1": {
      "failed_region": "us-east-1",
      "expected_working_region": "us-west-1",
      "chaos_injection_success": true,
      "connectivity_during_failure": {...},
      "restoration_success": true,
      "connectivity_after_restoration": {...},
      "overall_success": true
    }
  },
  "final_health_check": true
}
```

### Human-Readable Report
A formatted report is displayed at the end of each test run:

```
============================================================
LOCALSTACK CHAOS ENGINEERING TEST REPORT
============================================================
Start Time: 2025-05-24T21:00:00
End Time: 2025-05-24T21:05:00
Overall Status: PASSED

Scenario: disable_us_east_1
  Failed Region: us-east-1
  Expected Working Region: us-west-1
  Chaos Injection: ✓
  Restoration: ✓
  Overall Success: ✓

Final Health Check: ✓
============================================================
```

## Testing Methods

### DNS Resolution Testing
- Tests global endpoint: `example.com`
- Tests regional endpoints: `us-east-1.example.com`, `us-west-1.example.com`
- Uses `curl` with `--resolve` flag to bypass external DNS

### Container Connectivity Testing
- Discovers nginx container ports via `docker ps`
- Tests direct HTTP connectivity to containers
- Maps containers to regions based on naming conventions

### ECS Service Manipulation
- Uses AWS CLI with LocalStack endpoint
- Scales services up/down via `ecs update-service`
- Monitors service state changes

## Troubleshooting

### Common Issues

1. **LocalStack Not Running**
   ```
   Error: Failed to connect to LocalStack
   Solution: Run `make localstack-up` first
   ```

2. **Infrastructure Not Deployed**
   ```
   Error: Failed to list ECS services
   Solution: Run `make tf-up` to deploy infrastructure
   ```

3. **AWS CLI Not Configured**
   ```
   Error: AWS CLI authentication failed
   Solution: Run `make chaos-setup` to configure AWS CLI
   ```

4. **Container Ports Not Found**
   ```
   Warning: No container ports found
   Solution: Check that nginx containers are running with `docker ps`
   ```

### Debug Mode
Enable debug logging by modifying the script:
```python
logging.basicConfig(level=logging.DEBUG, ...)
```

### Manual Verification
You can manually verify the infrastructure state:

```bash
# Check LocalStack health
curl http://localhost:4666/health

# List ECS services
aws --endpoint-url=http://localhost:4666 ecs list-services --region=us-east-1 --cluster=nginx-hello-world-cluster-us-east-1

# Test DNS resolution
curl -s --resolve example.com:80:127.0.0.1 http://example.com

# Check running containers
docker ps | grep nginx
```

## Integration with CI/CD

The chaos test suite can be integrated into CI/CD pipelines:

```bash
# In your CI script
make all-up          # Deploy infrastructure
make chaos-test      # Run chaos tests
EXIT_CODE=$?         # Capture exit code
make all-down        # Clean up
exit $EXIT_CODE      # Propagate test result
```

## Extending the Test Suite

### Adding New Scenarios
1. Update `chaos_config.json` with new test scenarios
2. Modify the `ChaosTestSuite` class to handle new scenario types
3. Add new Makefile targets if needed

### Adding New Chaos Types
1. Implement new chaos injection methods (e.g., Route53 failures)
2. Add corresponding restoration methods
3. Update test scenarios to use new chaos types

### Custom Validation
1. Extend the connectivity testing methods
2. Add application-specific health checks
3. Implement custom metrics collection

## Best Practices

1. **Always run initial health check** before chaos injection
2. **Wait appropriate time** for changes to take effect
3. **Restore services** after each test scenario
4. **Verify restoration** before proceeding to next test
5. **Log all actions** for debugging and audit purposes
6. **Use timeouts** to prevent hanging tests
7. **Clean up state** between test runs

## Security Considerations

- The test suite uses test AWS credentials for LocalStack
- No real AWS resources are affected
- Container access is limited to localhost
- All chaos injection is reversible

## Performance Impact

- Tests typically take 2-5 minutes to complete
- Service downtime is limited to test duration
- No permanent changes to infrastructure
- Minimal resource usage during testing
