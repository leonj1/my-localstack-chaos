terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Create Route53 hosted zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.app_name}-zone"
    Environment = var.environment
  }
}

# Create latency-based routing record for global endpoint
resource "aws_route53_record" "global" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "global"
  
  latency_routing_policy {
    region = "global"
  }

  alias {
    name                   = var.global_alb_dns_name
    zone_id                = var.global_alb_zone_id
    evaluate_target_health = true
  }
}

# Create region-specific records
resource "aws_route53_record" "regional" {
  for_each = var.regional_endpoints

  zone_id = aws_route53_zone.main.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  set_identifier = each.key
  
  latency_routing_policy {
    region = each.value.region
  }

  alias {
    name                   = each.value.alb_dns_name
    zone_id                = each.value.alb_zone_id
    evaluate_target_health = true
  }
}

# Create latency-based routing records for each region
resource "aws_route53_record" "latency_based" {
  for_each = var.regional_endpoints

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = each.key
  
  latency_routing_policy {
    region = each.value.region
  }

  alias {
    name                   = each.value.alb_dns_name
    zone_id                = each.value.alb_zone_id
    evaluate_target_health = true
  }
}
