output "zone_id" {
  description = "The ID of the Route53 hosted zone"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "The name servers for the Route53 hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "global_dns" {
  description = "The global DNS endpoint with latency-based routing"
  value       = var.domain_name
}

output "regional_dns" {
  description = "The regional DNS endpoints"
  value       = { for k, v in var.regional_endpoints : k => "${k}.${var.domain_name}" }
}
