variable "role_name" {
  description = "IAM role name for CodePipeline."
  type        = string
}

variable "artifact_bucket_arn" {
  description = "S3 artifact bucket arn used by the pipeline."
  type        = string
}

variable "codebuild_role_arn" {
  description = "IAM role arn used by CodeBuild. Required for PassRole."
  type        = string
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection arn used by CodePipeline to connect to GitHub."
  type        = string
}

variable "kms_key_arns" {
  description = "Optional list of KMS key ARNs for decrypting SSE-KMS protected artifacts."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the CodePipeline IAM role."
  type        = map(string)
  default     = {}
}
