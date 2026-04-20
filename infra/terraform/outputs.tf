output "bucket_name" {
  description = "Provisioned S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "Provisioned S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

