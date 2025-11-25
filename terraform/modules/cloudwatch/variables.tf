variable "project_log_group_name" {
  description = "CloudWatch Log Group name for CodeBuild."
  type        = string
}

variable "pipeline_log_group_name" {
  description = "CloudWatch Log Group name for CodePipeline."
  type        = string
}

variable "log_retention_days" {
  description = "Retention period in days for CloudWatch Log Groups."
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encrypting CloudWatch Logs. If null, AWS-managed keys are used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the S3 bucket (merged with Service=Cloudwatch)."
  type        = map(string)
  default     = {}
}
