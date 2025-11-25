output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}

output "artifact_bucket_region" {
  value = aws_s3_bucket.artifacts.region
}
