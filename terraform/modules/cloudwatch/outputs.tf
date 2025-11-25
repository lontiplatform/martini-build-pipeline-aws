output "project_log_group_name" {
  value = aws_cloudwatch_log_group.project.name
}

output "project_log_group_arn" {
  value = aws_cloudwatch_log_group.project.arn
}

output "pipeline_log_group_name" {
  value = aws_cloudwatch_log_group.pipeline.name
}

output "pipeline_log_group_arn" {
  value = aws_cloudwatch_log_group.pipeline.arn
}
