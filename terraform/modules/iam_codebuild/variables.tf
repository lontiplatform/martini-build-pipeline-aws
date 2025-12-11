variable "role_name" {
  description = "IAM role name for the CodeBuild project."
  type        = string
}

variable "project_log_group_arn" {
  description = "CloudWatch log group ARN used by CodeBuild."
  type        = string
}

variable "artifact_bucket_arn" {
  description = "S3 artifact bucket arn used for CodePipeline/CodeBuild artifacts."
  type        = string
}

variable "ssm_parameter_arn" {
  description = "SSM SecureString parameter arn the project should read."
  type        = string
}

variable "ecr_repo_arn" {
  description = "ECR repository ARN for push/pull permissions. If null, ECR permissions are omitted."
  type        = string
  default     = null
}

variable "kms_key_arns" {
  description = "Optional list of KMS key ARNs for decrypting SSE-KMS protected S3/SSM artifacts."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the CodeBuild IAM role."
  type        = map(string)
  default     = {}
}
