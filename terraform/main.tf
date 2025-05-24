# Simple VPC setup for LocalStack free tier
resource "aws_vpc" "main_east" {
  provider   = aws.us_east_1
  cidr_block = "10.0.0.0/16"
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "nginx-hello-world-vpc-us-east-1"
    Environment = var.environment
  }
}

resource "aws_vpc" "main_west" {
  provider   = aws.us_west_1
  cidr_block = "10.1.0.0/16"
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "nginx-hello-world-vpc-us-west-1"
    Environment = var.environment
  }
}

# Internet Gateways
resource "aws_internet_gateway" "main_east" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.main_east.id

  tags = {
    Name        = "nginx-hello-world-igw-us-east-1"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main_west" {
  provider = aws.us_west_1
  vpc_id   = aws_vpc.main_west.id

  tags = {
    Name        = "nginx-hello-world-igw-us-west-1"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public_east" {
  provider          = aws.us_east_1
  vpc_id            = aws_vpc.main_east.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"
  
  map_public_ip_on_launch = true

  tags = {
    Name        = "nginx-hello-world-public-subnet-us-east-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_west" {
  provider          = aws.us_west_1
  vpc_id            = aws_vpc.main_west.id
  cidr_block        = "10.1.101.0/24"
  availability_zone = "us-west-1a"
  
  map_public_ip_on_launch = true

  tags = {
    Name        = "nginx-hello-world-public-subnet-us-west-1"
    Environment = var.environment
  }
}

# Route Tables
resource "aws_route_table" "public_east" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.main_east.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_east.id
  }

  tags = {
    Name        = "nginx-hello-world-public-rt-us-east-1"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_west" {
  provider = aws.us_west_1
  vpc_id   = aws_vpc.main_west.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_west.id
  }

  tags = {
    Name        = "nginx-hello-world-public-rt-us-west-1"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_east" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.public_east.id
  route_table_id = aws_route_table.public_east.id
}

resource "aws_route_table_association" "public_west" {
  provider       = aws.us_west_1
  subnet_id      = aws_subnet.public_west.id
  route_table_id = aws_route_table.public_west.id
}

# Route53 module for DNS management (simplified)
module "route53" {
  source = "./modules/route53"

  domain_name         = var.domain_name
  app_name            = var.app_name
  environment         = var.environment
  global_alb_dns_name = "dummy-nginx-hello-world-alb-us-east-1.amazonaws.com"
  global_alb_zone_id  = "DUMMY123456789"
  
  regional_endpoints = {
    "us-east-1" = {
      region       = "us-east-1"
      alb_dns_name = "dummy-nginx-hello-world-alb-us-east-1.amazonaws.com"
      alb_zone_id  = "DUMMY123456789"
    },
    "us-west-1" = {
      region       = "us-west-1"
      alb_dns_name = "dummy-nginx-hello-world-alb-us-west-1.amazonaws.com"
      alb_zone_id  = "DUMMY123456789"
    }
  }
}

# Outputs
output "vpc_id_east" {
  value = aws_vpc.main_east.id
}

output "vpc_id_west" {
  value = aws_vpc.main_west.id
}

output "route53_name_servers" {
  value = module.route53.name_servers
}

output "global_dns_endpoint" {
  value = module.route53.global_dns
}

output "regional_dns_endpoints" {
  value = module.route53.regional_dns
}
