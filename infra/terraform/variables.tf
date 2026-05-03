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

variable "task_execution_role_arn" {
  description = "Existing IAM role ARN for ECS task execution. Required in AWS lab accounts that cannot create IAM roles."
  type        = string
  default     = ""
}

variable "use_default_vpc" {
  description = "Use the account default VPC and subnets instead of creating a new VPC. Recommended for AWS lab accounts with strict VPC quotas."
  type        = bool
  default     = true
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
