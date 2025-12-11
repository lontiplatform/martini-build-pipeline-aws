output "pipeline_name" {
  value       = aws_codepipeline.martini_upload_pipeline.name
}

output "pipeline_arn" {
  value       = aws_codepipeline.martini_upload_pipeline.arn
}

output "codebuild_project_name" {
  value       = aws_codebuild_project.martini_upload_package.name
}

output "artifact_bucket_name" {
  value       = module.artifact_bucket.s3_bucket_id
}

output "ssm_parameter_name" {
  value       = local.ssm_parameter_name
}
