# Terraform (Phase 2)

This folder provisions an **S3 bucket** that meets rubric requirements:

- Unique bucket name (provided via `bucket_name`)
- Versioning enabled
- Encryption enabled (SSE-S3)
- Public access blocked

## Prereqs

- Terraform installed (1.5+ recommended)
- AWS credentials configured locally, or via GitHub Actions secrets

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

