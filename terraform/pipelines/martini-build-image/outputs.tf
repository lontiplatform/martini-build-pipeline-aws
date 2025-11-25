output "pipeline_name" {
  value       = aws_codepipeline.martini_build_pipeline.name
}

output "pipeline_arn" {
  value       = aws_codepipeline.martini_build_pipeline.arn
}

output "codebuild_project_name" {
  value       = aws_codebuild_project.martini_build_image.name
}

output "artifact_bucket_name" {
  value       = module.s3.artifact_bucket_name
}

output "ecr_repository_url" {
  value       = module.ecr.ecr_repository_url
}

output "ssm_parameter_name" {
  value       = module.ssm.ssm_parameter_name
}
