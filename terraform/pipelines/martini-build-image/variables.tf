variable "pipeline_name" {
  description = "Pipeline name, used for naming resources."
  type        = string
  default     = "martini-build-image"
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
  default     = "terraform/buildspecs/martini-build-image.yaml"
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar Connection for GitHub."
  type        = string
}

variable "martini_version" {
  description = "Version of the Martini runtime to include in the Docker image."
  type        = string
  default     = "latest"
}

variable "log_retention_days" {
  description = "Retention period in days for CloudWatch log groups."
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encryption of logs, S3, SSM, and artifacts."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
