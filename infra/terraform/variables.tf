variable "aws_region" {
  description = "AWS region to provision infrastructure in"
  type        = string
  default     = "ap-south-1"
}

variable "app_name" {
  description = "Name prefix for ECS, ECR, and load balancer resources"
  type        = string
  default     = "shopsmart"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the Shopsmart API container"
  type        = number
  default     = 5001
}

variable "vpc_cidr" {
  description = "CIDR block for the ECS VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets used by the ALB and Fargate tasks"
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "tags" {
  description = "Optional tags applied to resources"
  type        = map(string)
  default = {
    project = "shopsmart"
    owner   = "student"
  }
}
