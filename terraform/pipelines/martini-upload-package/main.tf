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
}

locals {
  environment             = var.environment
  pipeline_name           = var.pipeline_name
  resource_prefix         = "${local.environment}-${local.pipeline_name}"
  project_log_group_name  = "/aws/codebuild/${local.resource_prefix}"
  pipeline_log_group_name = "/aws/codepipeline/${local.resource_prefix}"
  artifact_bucket_name    = "${local.resource_prefix}-artifacts"
  codebuild_role_name     = "${local.resource_prefix}-codebuild-role"
  codepipeline_role_name  = "${local.resource_prefix}-codepipeline-role"
  ssm_parameter_name      = "/martini/${local.environment}/${local.pipeline_name}"

  common_tags = merge(
    var.tags,
    {
      Project     = "Martini"
      Environment = local.environment
      Owner       = "Lonti"
    }
  )
}

module "cloudwatch" {
  source = "../modules/cloudwatch"

  project_log_group_name  = local.project_log_group_name
  pipeline_log_group_name = local.pipeline_log_group_name
  log_retention_days      = var.log_retention_days
  kms_key_arn             = var.kms_key_arn
  tags                    = local.common_tags
}

module "s3" {
  source = "../modules/s3"

  bucket_name   = local.artifact_bucket_name
  kms_key_arn   = var.kms_key_arn
  tags          = local.common_tags
}

module "ssm" {
  source = "../modules/ssm"

  parameter_name        = local.ssm_parameter_name
  parameter_description = "Martini upload package parameter"

  parameter_value = jsonencode({
    base_url              = var.base_url
    martini_access_token  = var.martini_access_token
    async_upload          = var.async_upload
    success_check_delay   = var.success_check_delay
    success_check_timeout = var.success_check_timeout
  })

  kms_key_arn = var.kms_key_arn
  tags        = local.common_tags
}

module "iam_codebuild" {
  source = "../modules/iam_codebuild"

  role_name             = local.codebuild_role_name
  project_log_group_arn = module.cloudwatch.project_log_group_arn
  artifact_bucket_arn   = module.s3.artifact_bucket_arn
  ssm_parameter_arn     = module.ssm.ssm_parameter_arn
  ecr_repo_arn          = null
  kms_key_arns          = var.kms_key_arn != null ? [var.kms_key_arn] : []
  tags                  = local.common_tags
}

module "iam_codepipeline" {
  source = "../modules/iam_codepipeline"

  role_name             = local.codepipeline_role_name
  artifact_bucket_arn     = module.s3.artifact_bucket_arn
  codebuild_role_arn      = module.iam_codebuild.codebuild_role_arn
  codestar_connection_arn = var.codestar_connection_arn
  kms_key_arns            = var.kms_key_arn != null ? [var.kms_key_arn] : []
  tags                    = local.common_tags
}

resource "aws_codebuild_project" "martini_upload_package" {
  name          = local.resource_prefix
  description   = "Uploads Martini packages to a Martini runtime server."
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
      name  = "MARTINI_BASE_URL"
      value = var.base_url
    }

    environment_variable {
      name  = "PARAMETER_NAME"
      value = module.ssm.ssm_parameter_name
    }

    environment_variable {
      name  = "ASYNC_UPLOAD"
      value = tostring(var.async_upload)
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_filename
  }

  logs_config {
    cloudwatch_logs {
      group_name  = module.cloudwatch.project_log_group_name
      stream_name = "upload"
    }
  }

  tags = local.common_tags
}

resource "aws_codepipeline" "martini_upload_pipeline" {
  name     = local.resource_prefix
  role_arn = module.iam_codepipeline.codepipeline_role_arn

  artifact_store {
    location = module.s3.artifact_bucket_name
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
      name             = "UploadPackages"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["upload_output"]

      configuration = {
        ProjectName = aws_codebuild_project.martini_upload_package.name
      }
    }
  }

  tags = local.common_tags
}
