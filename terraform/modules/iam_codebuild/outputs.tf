output "codebuild_role_name" {
  value       = aws_iam_role.martini_codebuild_role.name
}

output "codebuild_role_arn" {
  value       = aws_iam_role.martini_codebuild_role.arn
}
