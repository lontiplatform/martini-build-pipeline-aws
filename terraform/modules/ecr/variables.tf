variable "repository_name" {
  description = "ECR repository name."
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for ECR image encryption. If null, AES256 encryption is used."
  type        = string
  default     = null
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on push."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the S3 bucket (merged with Service=ECR)."
  type        = map(string)
  default     = {}
}
