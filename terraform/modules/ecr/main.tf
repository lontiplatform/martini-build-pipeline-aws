locals {
  default_tags = {
    Service = "ECR"
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name                  = var.repository_name
  image_tag_mutability  = "MUTABLE"

  encryption_configuration {
    encryption_type = var.kms_key_arn != null ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(local.default_tags, var.tags)
}
