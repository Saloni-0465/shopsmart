output "bucket_name" {
  description = "Provisioned S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "Provisioned S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "aws_region" {
  description = "AWS region used by this stack"
  value       = var.aws_region
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Shopsmart API image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name expected by the deployment workflow"
  value       = "${var.app_name}-api"
}

output "task_execution_role_arn" {
  description = "IAM role ARN used by ECS tasks to pull images and write logs"
  value       = local.task_execution_role_arn
}

output "target_group_arn" {
  description = "ALB target group ARN for the ECS service"
  value       = aws_lb_target_group.app.arn
}

output "service_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.service.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by ECS Fargate"
  value       = local.public_subnet_ids
}

output "load_balancer_dns_name" {
  description = "Public DNS name for the Shopsmart API load balancer"
  value       = aws_lb.app.dns_name
}
