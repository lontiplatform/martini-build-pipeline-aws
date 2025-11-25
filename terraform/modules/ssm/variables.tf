variable "parameter_name" {
  description = "SSM parameter Name."
  type        = string
}

variable "parameter_description" {
  description = "SSM parameter description."
  type        = string
  default     = "Martini pipeline configuration parameter."
}

variable "parameter_value" {
  description = "The value to store in the SSM parameter. Must be JSON-encoded."
  type        = string
  sensitive   = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to encrypt the parameter. If null, AWS-managed key for SSM is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the S3 bucket (merged with Service=SSM)."
  type        = map(string)
  default     = {}
}
