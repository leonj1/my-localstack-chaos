output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_hostname" {
  description = "The DNS name of the ALB"
  value       = var.is_localstack ? local.dummy_alb_hostname : try(aws_lb.main[0].dns_name, local.dummy_alb_hostname)
}

output "alb_zone_id" {
  description = "The hosted zone ID of the ALB"
  value       = var.is_localstack ? local.dummy_alb_zone_id : try(aws_lb.main[0].zone_id, local.dummy_alb_zone_id)
}

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = var.is_localstack ? try(aws_ecs_service.localstack[0].name, "${var.app_name}-service-${var.region_name}") : try(aws_ecs_service.main[0].name, "${var.app_name}-service-${var.region_name}")
}
