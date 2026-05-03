# Terraform and ECS Deployment

This folder provisions the AWS infrastructure used by the Shopsmart pipeline.

The S3 bucket still meets the Phase 2 rubric requirements:

- Unique bucket name (provided via `bucket_name`)
- Versioning enabled
- Encryption enabled (SSE-S3)
- Public access blocked

It also provisions the ECS/Fargate foundation used by Phase 3:

- ECR repository for the Docker image
- ECS cluster
- CloudWatch log group
- Task execution IAM role
- Networking from the default VPC/subnets by default, or a dedicated VPC/subnets if `use_default_vpc=false`
- Application Load Balancer, target group, listener, and security groups

The ECS service and task definition revision are created or updated by GitHub Actions after the Docker image is pushed to ECR.

## Prereqs

- Terraform installed (1.5+ recommended)
- AWS credentials configured locally, or via GitHub Actions secrets
- A MySQL-compatible `DATABASE_URL` and `JWT_SECRET` configured as GitHub Actions secrets for the deployed app

## Usage (local)

```bash
cd infra/terraform
terraform init
terraform fmt -check
terraform validate
terraform plan -var="bucket_name=YOUR_UNIQUE_BUCKET_NAME" -var="aws_region=ap-south-1"
terraform apply -var="bucket_name=YOUR_UNIQUE_BUCKET_NAME" -var="aws_region=ap-south-1"
```

## Variables

- `bucket_name` (required): globally unique bucket name
- `aws_region` (optional): defaults to `ap-south-1`
- `app_name` (optional): defaults to `shopsmart`
- `container_port` (optional): defaults to `5001`
- `task_execution_role_arn` (optional): use an existing ECS-compatible IAM role, such as a lab-provided role, when the AWS account cannot create IAM roles
- `use_default_vpc` (optional): defaults to `true` to avoid VPC quota issues in AWS lab accounts
