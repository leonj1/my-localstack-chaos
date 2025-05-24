variable "domain_name" {
  description = "The domain name for the Route53 hosted zone"
  type        = string
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment (dev, prod, etc.)"
  type        = string
}

variable "global_alb_dns_name" {
  description = "The DNS name of the global ALB"
  type        = string
}

variable "global_alb_zone_id" {
  description = "The hosted zone ID of the global ALB"
  type        = string
}

variable "regional_endpoints" {
  description = "Map of regional endpoints with their ALB DNS names and zone IDs"
  type = map(object({
    region       = string
    alb_dns_name = string
    alb_zone_id  = string
  }))
}
