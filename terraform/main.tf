module "ecs_east" {
  source = "./modules/ecs"
  providers = {
    aws = aws.us_east_1
  }

  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24"]
  container_image     = var.container_image
  container_port      = var.container_port
  region_name         = "us-east-1"
  app_name            = var.app_name
  app_count           = var.app_count
  is_localstack       = var.is_localstack
}

module "ecs_west" {
  source = "./modules/ecs"
  providers = {
    aws = aws.us_west_1
  }

  environment         = var.environment
  vpc_cidr            = "10.1.0.0/16"
  availability_zones  = ["us-west-1a", "us-west-1b"]
  private_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets      = ["10.1.101.0/24", "10.1.102.0/24"]
  container_image     = var.container_image
  container_port      = var.container_port
  region_name         = "us-west-1"
  app_name            = var.app_name
  app_count           = var.app_count
  is_localstack       = var.is_localstack
}

# Route53 module for DNS management
module "route53" {
  source = "./modules/route53"

  domain_name         = var.domain_name
  app_name            = var.app_name
  environment         = var.environment
  global_alb_dns_name = module.ecs_east.alb_hostname  # Using East as global default
  global_alb_zone_id  = module.ecs_east.alb_zone_id
  
  regional_endpoints = {
    "us-east-1" = {
      region       = "us-east-1"
      alb_dns_name = module.ecs_east.alb_hostname
      alb_zone_id  = module.ecs_east.alb_zone_id
    },
    "us-west-1" = {
      region       = "us-west-1"
      alb_dns_name = module.ecs_west.alb_hostname
      alb_zone_id  = module.ecs_west.alb_zone_id
    }
  }
}

output "alb_hostname_east" {
  value = module.ecs_east.alb_hostname
}

output "alb_hostname_west" {
  value = module.ecs_west.alb_hostname
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
