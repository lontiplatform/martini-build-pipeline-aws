variable "pipeline_name" {
  description = "Pipeline name"
  type        = string
  default     = "martini-upload-package"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
}

variable "repository_name" {
  description = "Full GitHub repository name (e.g., username/repo)."
  type        = string
}

variable "branch_name" {
  description = "Branch name for CodePipeline source trigger."
  type        = string
  default     = "main"
}

variable "buildspec_filename" {
  description = "The buildspec file for the CodeBuild project."
  type        = string
  default     = "terraform/buildspecs/martini-upload-package.yaml"
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar Connection for GitHub."
  type        = string
}

variable "base_url" {
  description = "URL of the target Martini runtime server to which packages are uploaded."
  type        = string
}

variable "martini_access_token" {
  description = "Long-lived OAuth token used to authenticate with the Martini runtime."
  type        = string
  sensitive   = true
}

variable "async_upload" {
  description = "Use async upload mode. If null, upload_packages.sh default is used."
  type        = bool
  default     = null
}

variable "success_check_delay" {
  description = "Polling delay in seconds. If null, script default is used."
  type        = number
  default     = null
}

variable "success_check_timeout" {
  description = "Polling timeout count. If null, script default is used."
  type        = number
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encrypting logs, S3 buckets, and SSM."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
