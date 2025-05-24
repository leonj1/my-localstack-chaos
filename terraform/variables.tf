variable "environment" {
  description = "The environment (dev, prod, etc.)"
  default     = "dev"
}

variable "app_name" {
  description = "The name of the application"
  default     = "nginx-hello-world"
}

variable "app_count" {
  description = "Number of instances of the application to run"
  default     = 2
}

variable "container_image" {
  description = "The container image to use"
  default     = "nginx:latest"
}

variable "container_port" {
  description = "The port the container exposes"
  default     = 80
}

variable "domain_name" {
  description = "The domain name for the Route53 hosted zone"
  default     = "example.com"
}

variable "is_localstack" {
  description = "Whether we are running in LocalStack mode"
  type        = bool
  default     = true
}
