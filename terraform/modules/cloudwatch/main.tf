locals {
  default_tags = {
    Service = "CloudWatch"
  }
}

resource "aws_cloudwatch_log_group" "project" {
  name              = var.project_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(local.default_tags, var.tags)
}

resource "aws_cloudwatch_log_group" "pipeline" {
  name              = var.pipeline_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(local.default_tags, var.tags)
}
