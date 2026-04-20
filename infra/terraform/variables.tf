variable "aws_region" {
  description = "AWS region to provision infrastructure in"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "tags" {
  description = "Optional tags applied to resources"
  type        = map(string)
  default = {
    project = "shopsmart"
    owner   = "student"
  }
}

