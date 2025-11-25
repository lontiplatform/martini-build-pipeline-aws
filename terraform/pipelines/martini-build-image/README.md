# Martini Build Image with AWS CodePipeline

This Terraform stack configures an AWS CodePipeline for building Docker images that integrate the Martini Server Runtime and Martini packages. The image is pushed to ECR and can be used as the base image for deployment.

---

## Overview

The **martini-build-image** pipeline:

- Uses GitHub (via CodeStar Connections) as the source repository.
- Triggers on changes to a configured branch.
- Runs an AWS CodeBuild project that:
  - Uses the `martini-build-image.yaml` buildspec.
  - Uses `terraform/scripts/dockerfile` to build the image.
  - Downloads or otherwise includes Martini runtime and packages.
  - Builds and pushes an image to a configured ECR repository.
- Stores logs in CloudWatch and artifacts in S3.
- Uses SSM Parameter Store for build-time configuration, including the Martini version and any package configuration required by the buildspec.

---

## Repository Structure

In this folder:

- `main.tf` – Wires up modules for IAM, S3, CloudWatch, SSM, ECR, CodeBuild, and CodePipeline.
- `variables.tf` – Input variables used to parameterize the stack (see table below).
- `outputs.tf` – Exposes key resource names and ARNs (e.g., CodeBuild project, CodePipeline, SSM parameter name).

Other referenced files:

- `../../buildspecs/martini-build-image.yaml` – Buildspec used by CodeBuild.
- `../../scripts/dockerfile` – Dockerfile used to build the Martini image.
- Modules from `../../modules/*` – Shared components (cloudwatch, ecr, iam, s3, ssm, etc.).

---

## Requirements

- Terraform 1.3.0+
- AWS credentials with permission to create:
  - CodePipeline, CodeBuild, ECR, S3, SSM, CloudWatch, IAM
- An existing CodeStar **connection ARN** to the GitHub repository containing this code.
- An existing ECR repository (or this stack may create one, depending on the underlying module implementation).

---

## Usage

Example usage:

```bash
cd terraform/pipelines/martini-build-image

terraform init
terraform plan -var="pipeline_name=martini-build-image" \
               -var="repository_name=your-org/your-repo" \
               -var="branch_name=main" \
               -var="connection_arn=arn:aws:codestar-connections:..." \
               -var="ecr_repo_name=martini-runtime" \
               -var="log_retention_days=14" \
               -var='tags={ Environment = "dev", Project = "martini" }'
terraform apply
```

You can also provide these variables via `terraform.tfvars`.

After apply:

- A CodePipeline and CodeBuild project are created.
- The pipeline listens to commits on `branch_name` of `repository_name`.
- Pushing a change to that branch (including to buildspecs or scripts) will trigger a new image build.

---

## Input Reference

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| pipeline_name | Pipeline name, used for naming resources. | string | "martini-build-image" | no |
| environment | Deployment environment (e.g., dev, staging, prod). | string | "dev" | no |
| aws_region | AWS region for deployment. | string | n/a | yes |
| repository_name | Full GitHub repository name (e.g., username/repo). | string | n/a | yes |
| branch_name | Branch name for CodePipeline source trigger. | string | "main" | no |
| buildspec_filename | Buildspec file for CodeBuild. | string | "terraform/buildspecs/martini-build-image.yaml" | no |
| codestar_connection_arn | ARN of the AWS CodeStar Connection for GitHub. | string | n/a | yes |
| martini_version | Version of the Martini runtime to include in the Docker image. | string | "latest" | no |
| log_retention_days | Retention period (days) for CloudWatch logs. | number | 90 | no |
| kms_key_arn | Optional KMS key ARN for encryption. | string | null | no |
| tags | Additional tags applied to resources. | map(string) | {} | no |

---

## Notes

- **Buildspec and Dockerfile**: This stack assumes that `buildspec_file` and the Dockerfile referenced by it exist in the GitHub repository used as the pipeline source.
- **SSM Parameter Store**: The SSM parameter referenced by `parameter_name` should contain any build-time configuration required by the buildspec, such as:
  - Martini version override
  - Extra flags or configuration JSON
- **Monitoring & Debugging**:
  - CloudWatch log groups for CodeBuild and CodePipeline are created via the shared modules.
  - Use these logs to troubleshoot build or pipeline failures.
