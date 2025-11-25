output "ssm_parameter_name" {
  value = aws_ssm_parameter.ssm_parameter.name
}

output "ssm_parameter_arn" {
  value = aws_ssm_parameter.ssm_parameter.arn
}
