variable "bucket_name" {
  description = "S3 artifact bucket name."
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN to use for bucket encryption. If null, AES256 encryption is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the S3 bucket (merged with Service=S3)."
  type        = map(string)
  default     = {}
}
