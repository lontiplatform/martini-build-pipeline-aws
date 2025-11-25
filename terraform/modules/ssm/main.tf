locals {
  default_tags = {
    Service = "SSM"
  }
}

resource "aws_ssm_parameter" "ssm_parameter" {
  name        = var.parameter_name
  description = var.parameter_description
  type        = "SecureString"
  value       = var.parameter_value
  key_id      = var.kms_key_arn
  overwrite   = true

  tags = merge(local.default_tags, var.tags)
}
