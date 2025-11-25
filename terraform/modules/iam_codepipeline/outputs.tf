output "codepipeline_role_name" {
  value       = aws_iam_role.martini_codepipeline_role.name
}

output "codepipeline_role_arn" {
  value       = aws_iam_role.martini_codepipeline_role.arn
}
