locals {
  default_tags = {
    Service = "CodePipeline"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = merge(local.default_tags, var.tags)
}

data "aws_iam_policy_document" "codepipeline_permissions" {

  # CodeStar — required for GitHub source access
  statement {
    sid       = "CodeStarConnection"
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.codestar_connection_arn]
  }

  statement {
    sid       = "S3ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.artifact_bucket_arn]
  }

  statement {
    sid       = "S3ArtifactObjects"
    actions   = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.artifact_bucket_arn}/*"]
  }

  statement {
    sid       = "PassRoleToCodeBuild"
    actions   = ["iam:PassRole"]
    resources = [var.codebuild_role_arn]
  }

  statement {
    sid       = "CodeBuildIntegration"
    actions   = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arns) == 0 ? [] : [1]

    content {
      sid       = "KMSDecrypt"
      actions   = ["kms:Decrypt"]
      resources = var.kms_key_arns
    }
  }

  statement {
    sid       = "CloudWatchEvents"
    actions   = [
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:DescribeRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_inline" {
  name   = "codepipeline-inline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_permissions.json
}
