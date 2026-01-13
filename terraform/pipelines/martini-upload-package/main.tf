terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Project     = "Martini"
        Environment = var.environment
        Owner       = "Lonti"
      }
    )
  }
}

locals {
  environment       = var.environment
  pipeline_name     = var.pipeline_name
  resource_prefix   = "${local.environment}-${local.pipeline_name}"

  project_log_group_name  = "/aws/codebuild/${local.resource_prefix}"
  pipeline_log_group_name = "/aws/codepipeline/${local.resource_prefix}"

  artifact_bucket_name   = "${local.resource_prefix}-artifacts"
  codebuild_role_name    = "${local.resource_prefix}-codebuild-role"
  codepipeline_role_name = "${local.resource_prefix}-codepipeline-role"

  ssm_parameter_name = "/martini/${local.environment}/${local.pipeline_name}"

  upload_package_ssm_value = merge(
    {
      base_url             = var.base_url
      martini_access_token = var.martini_access_token
    },
    var.async_upload == null ? {} : { async_upload = var.async_upload },
    var.success_check_delay == null ? {} : { success_check_delay = var.success_check_delay },
    var.success_check_timeout == null ? {} : { success_check_timeout = var.success_check_timeout }
  )
}

module "project_log_group" {
  # checkov:skip=CKV_AWS_338: Shorter log retention acceptable for pipeline logs

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 5.0"

  name              = local.project_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

module "pipeline_log_group" {
  # checkov:skip=CKV_AWS_338: Shorter log retention acceptable for pipeline logs

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 5.0"

  name              = local.pipeline_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

module "artifact_bucket" {
  # checkov:skip=CKV_AWS_18: Access logging not required for ephemeral artifact bucket
  # checkov:skip=CKV_AWS_21: Versioning explicitly enabled via module configuration
  # checkov:skip=CKV_AWS_144: Cross-region replication not required for pipeline artifact bucket
  # checkov:skip=CKV_AWS_145: KMS key is optional; default SSE-S3 encryption is sufficient
  # checkov:skip=CKV_AWS_300: Abort multipart uploads configured via lifecycle_rule
  # checkov:skip=CKV2_AWS_6: S3 module blocks public access by default
  # checkov:skip=CKV2_AWS_61: Lifecycle rules configured
  # checkov:skip=CKV2_AWS_62: Bucket does not require event notifications

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket        = local.artifact_bucket_name
  force_destroy = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "cleanup-artifacts"
      enabled = true

      expiration = {
        days = 30
      }

      noncurrent_version_expiration = {
        noncurrent_days = 7
      }
    },
    {
      id      = "abort-multipart"
      enabled = true

      expiration = {
        expired_object_delete_marker = false
      }

      abort_incomplete_multipart_upload = {
        days_after_initiation = 1
      }
    }
  ]

  server_side_encryption_configuration = var.kms_key_arn == null ? {} : {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "upload_package_parameter" {
  # checkov:skip=CKV2_AWS_34: Parameter is set as SecureString and at default is encrypted at rest; CMK used when provided

  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 2.0"

  name        = local.ssm_parameter_name
  description = "Martini upload package parameter"

  secure_type = true
  key_id      = var.kms_key_arn

  value = jsonencode(local.upload_package_ssm_value)
}

module "iam_codebuild" {
  source = "../../modules/iam_codebuild"

  role_name             = local.codebuild_role_name
  project_log_group_arn = module.project_log_group.cloudwatch_log_group_arn
  artifact_bucket_arn   = module.artifact_bucket.s3_bucket_arn
  ssm_parameter_arn     = module.upload_package_parameter.ssm_parameter_arn
  kms_key_arns          = var.kms_key_arn != null ? [var.kms_key_arn] : []
}

module "iam_codepipeline" {
  source = "../../modules/iam_codepipeline"

  role_name               = local.codepipeline_role_name
  artifact_bucket_arn     = module.artifact_bucket.s3_bucket_arn
  codebuild_role_arn      = module.iam_codebuild.codebuild_role_arn
  codestar_connection_arn = var.codestar_connection_arn
  kms_key_arns            = var.kms_key_arn != null ? [var.kms_key_arn] : []
}

resource "aws_codebuild_project" "martini_upload_package" {
  # checkov:skip=CKV_AWS_147: CMK encryption not required for CodeBuild logs/artifacts

  name          = local.resource_prefix
  description   = "Builds Martini packages and uploads them."
  service_role  = module.iam_codebuild.codebuild_role_arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "UPLOAD_PACKAGE_PARAMETER"
      value = local.ssm_parameter_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_filename
  }

  logs_config {
    cloudwatch_logs {
      group_name  = module.project_log_group.cloudwatch_log_group_name
      stream_name = "upload"
    }
  }
}

resource "aws_codepipeline" "martini_upload_pipeline" {
  name     = local.resource_prefix
  role_arn = module.iam_codepipeline.codepipeline_role_arn

  artifact_store {
    location = module.artifact_bucket.s3_bucket_id
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.kms_key_arn != null ? [1] : []
      content {
        id   = var.kms_key_arn
        type = "KMS"
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.repository_name
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "Upload"

    action {
      name             = "UploadPackage"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.martini_upload_package.name
      }
    }
  }
}
