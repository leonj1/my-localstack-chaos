variable "environment" {
  description = "The environment (dev, prod, etc.)"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "The availability zones to use"
  type        = list(string)
}

variable "private_subnets" {
  description = "The private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "The public subnet CIDR blocks"
  type        = list(string)
}

variable "container_image" {
  description = "The container image to use"
  type        = string
}

variable "container_port" {
  description = "The port the container exposes"
  type        = number
}

variable "region_name" {
  description = "The AWS region name"
  type        = string
}

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "app_count" {
  description = "Number of instances of the application to run"
  type        = number
}

variable "is_localstack" {
  description = "Whether we are running in LocalStack mode"
  type        = bool
  default     = true
}
