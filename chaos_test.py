#!/usr/bin/env python3
"""
LocalStack Chaos Engineering Test Suite

This script tests the resilience of a multi-region web server deployment
by simulating region failures using LocalStack's chaos engineering features.
"""

import json
import time
import requests
import subprocess
import sys
import argparse
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('chaos_test.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class ChaosTestSuite:
    """Main class for chaos engineering tests"""
    
    def __init__(self):
        # Use Docker gateway IP when running in container, localhost otherwise
        import os
        if os.path.exists('/.dockerenv'):
            # We're running in a container, use Docker gateway
            self.localstack_endpoint = "http://172.17.0.1:4666"
        else:
            # We're running on host, use localhost
            self.localstack_endpoint = "http://localhost:4666"
        
        self.regions = ["us-east-1", "us-west-1"]
        self.domain = "example.com"
        self.test_results = {
            "start_time": datetime.now().isoformat(),
            "scenarios": {},
            "overall_status": "UNKNOWN"
        }
        
    def check_localstack_health(self) -> bool:
        """Check if LocalStack is running and healthy"""
        try:
            response = requests.get(f"{self.localstack_endpoint}/_localstack/health", timeout=10)
            if response.status_code == 200:
                health_data = response.json()
                logger.info(f"LocalStack health check passed: {health_data}")
                return True
            else:
                logger.error(f"LocalStack health check failed with status: {response.status_code}")
                return False
        except Exception as e:
            logger.error(f"Failed to connect to LocalStack: {e}")
            return False
    
    def get_ecs_services(self, region: str) -> List[Dict]:
        """Get ECS services in a specific region"""
        try:
            # Use AWS CLI to list ECS services
            cmd = [
                "aws", "--endpoint-url", self.localstack_endpoint,
                "ecs", "list-services",
                "--region", region,
                "--cluster", f"nginx-hello-world-cluster-{region}"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                services_data = json.loads(result.stdout)
                logger.info(f"Found {len(services_data.get('serviceArns', []))} ECS services in {region}")
                return services_data.get('serviceArns', [])
            else:
                logger.error(f"Failed to list ECS services in {region}: {result.stderr}")
                return []
        except Exception as e:
            logger.error(f"Error getting ECS services in {region}: {e}")
            return []
    
    def test_dns_resolution(self) -> Dict[str, bool]:
        """Test DNS resolution for global and regional endpoints"""
        results = {}
        
        # Test global endpoint
        try:
            cmd = ["curl", "-s", "--resolve", f"{self.domain}:80:127.0.0.1", 
                   f"http://{self.domain}", "--max-time", "10"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            results["global"] = result.returncode == 0
            if results["global"]:
                logger.info(f"Global DNS endpoint accessible: {self.domain}")
            else:
                logger.warning(f"Global DNS endpoint failed: {result.stderr}")
        except Exception as e:
            logger.error(f"DNS test failed for global endpoint: {e}")
            results["global"] = False
        
        # Test regional endpoints
        for region in self.regions:
            regional_domain = f"{region}.{self.domain}"
            try:
                cmd = ["curl", "-s", "--resolve", f"{regional_domain}:80:127.0.0.1", 
                       f"http://{regional_domain}", "--max-time", "10"]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
                results[region] = result.returncode == 0
                if results[region]:
                    logger.info(f"Regional DNS endpoint accessible: {regional_domain}")
                else:
                    logger.warning(f"Regional DNS endpoint failed: {result.stderr}")
            except Exception as e:
                logger.error(f"DNS test failed for {region}: {e}")
                results[region] = False
        
        return results
    
    def get_container_ports(self) -> Dict[str, Optional[int]]:
        """Get the exposed container ports for nginx containers"""
        ports = {}
        
        try:
            # Get running containers
            cmd = ["docker", "ps", "--format", "json"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                containers = []
                for line in result.stdout.strip().split('\n'):
                    if line:
                        containers.append(json.loads(line))
                
                # Find nginx containers and extract ports
                for container in containers:
                    if 'nginx' in container.get('Image', '').lower():
                        ports_info = container.get('Ports', '')
                        # Parse port mapping like "0.0.0.0:32768->80/tcp"
                        if '->' in ports_info:
                            external_port = ports_info.split(':')[1].split('->')[0]
                            # Determine region based on container name or other identifier
                            container_name = container.get('Names', '')
                            if 'east' in container_name.lower():
                                ports['us-east-1'] = int(external_port)
                            elif 'west' in container_name.lower():
                                ports['us-west-1'] = int(external_port)
                            else:
                                # If we can't determine region, assign to available slot
                                if 'us-east-1' not in ports:
                                    ports['us-east-1'] = int(external_port)
                                elif 'us-west-1' not in ports:
                                    ports['us-west-1'] = int(external_port)
                
                logger.info(f"Found container ports: {ports}")
            else:
                logger.error(f"Failed to get container information: {result.stderr}")
        
        except Exception as e:
            logger.error(f"Error getting container ports: {e}")
        
        return ports
    
    def test_container_connectivity(self, ports: Dict[str, int]) -> Dict[str, bool]:
        """Test direct connectivity to nginx containers"""
        results = {}
        
        for region, port in ports.items():
            try:
                response = requests.get(f"http://localhost:{port}", timeout=10)
                results[region] = response.status_code == 200
                if results[region]:
                    logger.info(f"Container connectivity successful for {region} on port {port}")
                    logger.debug(f"Response content: {response.text[:100]}...")
                else:
                    logger.warning(f"Container connectivity failed for {region} on port {port}: HTTP {response.status_code}")
            except Exception as e:
                logger.error(f"Container connectivity test failed for {region} on port {port}: {e}")
                results[region] = False
        
        return results
    
    def inject_chaos_ecs_failure(self, region: str) -> bool:
        """Inject chaos by scaling down ECS services in a region"""
        try:
            # Scale down ECS service to 0 tasks
            cmd = [
                "aws", "--endpoint-url", self.localstack_endpoint,
                "ecs", "update-service",
                "--region", region,
                "--cluster", f"nginx-hello-world-cluster-{region}",
                "--service", f"nginx-hello-world-service-{region}",
                "--desired-count", "0"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logger.info(f"Successfully scaled down ECS service in {region}")
                # Wait for the change to take effect
                time.sleep(10)
                return True
            else:
                logger.error(f"Failed to scale down ECS service in {region}: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error injecting ECS chaos in {region}: {e}")
            return False
    
    def restore_ecs_service(self, region: str) -> bool:
        """Restore ECS service by scaling back up"""
        try:
            # Scale up ECS service back to 2 tasks
            cmd = [
                "aws", "--endpoint-url", self.localstack_endpoint,
                "ecs", "update-service",
                "--region", region,
                "--cluster", f"nginx-hello-world-cluster-{region}",
                "--service", f"nginx-hello-world-service-{region}",
                "--desired-count", "2"
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                logger.info(f"Successfully scaled up ECS service in {region}")
                # Wait for the service to become healthy
                time.sleep(15)
                return True
            else:
                logger.error(f"Failed to scale up ECS service in {region}: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Error restoring ECS service in {region}: {e}")
            return False
    
    def inject_chaos_route53_failure(self, region: str) -> bool:
        """Inject chaos by modifying Route53 records to point to invalid targets"""
        try:
            # This is a placeholder for Route53 chaos injection
            # In a real scenario, we would modify DNS records to simulate failures
            logger.info(f"Simulating Route53 failure for {region} (placeholder)")
            return True
        except Exception as e:
            logger.error(f"Error injecting Route53 chaos in {region}: {e}")
            return False
    
    def initial_health_check(self) -> bool:
        """Perform initial health check of all services"""
        logger.info("=== Starting Initial Health Check ===")
        
        # Check LocalStack health
        if not self.check_localstack_health():
            logger.error("LocalStack health check failed")
            return False
        
        # Test DNS resolution
        dns_results = self.test_dns_resolution()
        
        # Get container ports and test connectivity
        container_ports = self.get_container_ports()
        if not container_ports:
            logger.warning("No container ports found, skipping container connectivity tests")
            container_results = {}
        else:
            container_results = self.test_container_connectivity(container_ports)
        
        # Check if at least one region is working
        working_regions = []
        for region in self.regions:
            dns_ok = dns_results.get(region, False)
            container_ok = container_results.get(region, True)  # Default to True if no containers found
            
            if dns_ok or container_ok:
                working_regions.append(region)
                logger.info(f"Region {region} is healthy (DNS: {dns_ok}, Container: {container_ok})")
            else:
                logger.warning(f"Region {region} appears unhealthy (DNS: {dns_ok}, Container: {container_ok})")
        
        if len(working_regions) >= 1:
            logger.info(f"Initial health check passed. Working regions: {working_regions}")
            return True
        else:
            logger.error("Initial health check failed. No regions are working.")
            return False
    
    def test_scenario(self, failed_region: str, expected_working_region: str) -> Dict:
        """Test a specific failure scenario"""
        scenario_name = f"disable_{failed_region}"
        logger.info(f"=== Testing Scenario: {scenario_name} ===")
        
        scenario_result = {
            "failed_region": failed_region,
            "expected_working_region": expected_working_region,
            "chaos_injection_success": False,
            "connectivity_during_failure": {},
            "restoration_success": False,
            "connectivity_after_restoration": {},
            "overall_success": False
        }
        
        # Step 1: Inject chaos
        logger.info(f"Step 1: Injecting chaos in {failed_region}")
        chaos_success = self.inject_chaos_ecs_failure(failed_region)
        scenario_result["chaos_injection_success"] = chaos_success
        
        if not chaos_success:
            logger.error(f"Failed to inject chaos in {failed_region}")
            return scenario_result
        
        # Step 2: Test connectivity during failure
        logger.info(f"Step 2: Testing connectivity during {failed_region} failure")
        dns_results = self.test_dns_resolution()
        container_ports = self.get_container_ports()
        container_results = self.test_container_connectivity(container_ports) if container_ports else {}
        
        scenario_result["connectivity_during_failure"] = {
            "dns": dns_results,
            "containers": container_results
        }
        
        # Check if the expected working region is still accessible
        working_region_ok = (
            dns_results.get(expected_working_region, False) or 
            container_results.get(expected_working_region, False)
        )
        
        if working_region_ok:
            logger.info(f"SUCCESS: {expected_working_region} is still accessible during {failed_region} failure")
        else:
            logger.error(f"FAILURE: {expected_working_region} is not accessible during {failed_region} failure")
        
        # Step 3: Restore the failed region
        logger.info(f"Step 3: Restoring {failed_region}")
        restore_success = self.restore_ecs_service(failed_region)
        scenario_result["restoration_success"] = restore_success
        
        if not restore_success:
            logger.error(f"Failed to restore {failed_region}")
            return scenario_result
        
        # Step 4: Test connectivity after restoration
        logger.info(f"Step 4: Testing connectivity after {failed_region} restoration")
        dns_results_after = self.test_dns_resolution()
        container_ports_after = self.get_container_ports()
        container_results_after = self.test_container_connectivity(container_ports_after) if container_ports_after else {}
        
        scenario_result["connectivity_after_restoration"] = {
            "dns": dns_results_after,
            "containers": container_results_after
        }
        
        # Check if both regions are working after restoration
        both_regions_ok = True
        for region in self.regions:
            region_ok = (
                dns_results_after.get(region, False) or 
                container_results_after.get(region, False)
            )
            if not region_ok:
                both_regions_ok = False
                logger.warning(f"Region {region} not fully restored")
        
        scenario_result["overall_success"] = working_region_ok and restore_success and both_regions_ok
        
        if scenario_result["overall_success"]:
            logger.info(f"Scenario {scenario_name} completed successfully")
        else:
            logger.error(f"Scenario {scenario_name} failed")
        
        return scenario_result
    
    def run_full_test_suite(self) -> Dict:
        """Run the complete chaos engineering test suite"""
        logger.info("=== Starting LocalStack Chaos Engineering Test Suite ===")
        
        # Initial health check
        if not self.initial_health_check():
            self.test_results["overall_status"] = "FAILED"
            self.test_results["error"] = "Initial health check failed"
            return self.test_results
        
        # Scenario A: Disable us-east-1, test us-west-1
        scenario_a = self.test_scenario("us-east-1", "us-west-1")
        self.test_results["scenarios"]["disable_us_east_1"] = scenario_a
        
        # Wait between scenarios
        logger.info("Waiting 10 seconds between scenarios...")
        time.sleep(10)
        
        # Scenario B: Disable us-west-1, test us-east-1
        scenario_b = self.test_scenario("us-west-1", "us-east-1")
        self.test_results["scenarios"]["disable_us_west_1"] = scenario_b
        
        # Final health check
        logger.info("=== Final Health Check ===")
        final_health = self.initial_health_check()
        self.test_results["final_health_check"] = final_health
        
        # Determine overall status
        all_scenarios_passed = all(
            scenario["overall_success"] 
            for scenario in self.test_results["scenarios"].values()
        )
        
        if all_scenarios_passed and final_health:
            self.test_results["overall_status"] = "PASSED"
            logger.info("🎉 All chaos engineering tests PASSED!")
        else:
            self.test_results["overall_status"] = "FAILED"
            logger.error("❌ Some chaos engineering tests FAILED!")
        
        self.test_results["end_time"] = datetime.now().isoformat()
        
        return self.test_results
    
    def run_single_scenario(self, scenario: str) -> Dict:
        """Run a single chaos engineering scenario"""
        logger.info(f"=== Running Single Scenario: {scenario} ===")
        
        # Initial health check
        if not self.initial_health_check():
            return {"error": "Initial health check failed"}
        
        if scenario == "us-east-1":
            result = self.test_scenario("us-east-1", "us-west-1")
        elif scenario == "us-west-1":
            result = self.test_scenario("us-west-1", "us-east-1")
        else:
            return {"error": f"Unknown scenario: {scenario}"}
        
        return {"scenario": result}
    
    def generate_report(self) -> str:
        """Generate a human-readable test report"""
        report = []
        report.append("=" * 60)
        report.append("LOCALSTACK CHAOS ENGINEERING TEST REPORT")
        report.append("=" * 60)
        report.append(f"Start Time: {self.test_results.get('start_time', 'Unknown')}")
        report.append(f"End Time: {self.test_results.get('end_time', 'Unknown')}")
        report.append(f"Overall Status: {self.test_results.get('overall_status', 'Unknown')}")
        report.append("")
        
        for scenario_name, scenario_data in self.test_results.get("scenarios", {}).items():
            report.append(f"Scenario: {scenario_name}")
            report.append(f"  Failed Region: {scenario_data.get('failed_region', 'Unknown')}")
            report.append(f"  Expected Working Region: {scenario_data.get('expected_working_region', 'Unknown')}")
            report.append(f"  Chaos Injection: {'✓' if scenario_data.get('chaos_injection_success') else '✗'}")
            report.append(f"  Restoration: {'✓' if scenario_data.get('restoration_success') else '✗'}")
            report.append(f"  Overall Success: {'✓' if scenario_data.get('overall_success') else '✗'}")
            report.append("")
        
        report.append(f"Final Health Check: {'✓' if self.test_results.get('final_health_check') else '✗'}")
        report.append("=" * 60)
        
        return "\n".join(report)


def main():
    parser = argparse.ArgumentParser(description="LocalStack Chaos Engineering Test Suite")
    parser.add_argument("--scenario", choices=["us-east-1", "us-west-1"], 
                       help="Run a specific scenario only")
    parser.add_argument("--quick", action="store_true", 
                       help="Run quick health check only")
    parser.add_argument("--full-test", action="store_true", 
                       help="Run full test suite (default)")
    parser.add_argument("--output", default="chaos_test_results.json",
                       help="Output file for test results")
    
    args = parser.parse_args()
    
    chaos_suite = ChaosTestSuite()
    
    try:
        if args.quick:
            # Quick health check only
            logger.info("Running quick health check...")
            health_ok = chaos_suite.initial_health_check()
            print(f"Health Check: {'PASSED' if health_ok else 'FAILED'}")
            sys.exit(0 if health_ok else 1)
        
        elif args.scenario:
            # Run single scenario
            results = chaos_suite.run_single_scenario(args.scenario)
        else:
            # Run full test suite
            results = chaos_suite.run_full_test_suite()
        
        # Save results to file
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
        
        # Generate and display report
        report = chaos_suite.generate_report()
        print("\n" + report)
        
        # Exit with appropriate code
        overall_status = results.get("overall_status", "FAILED")
        sys.exit(0 if overall_status == "PASSED" else 1)
        
    except KeyboardInterrupt:
        logger.info("Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
