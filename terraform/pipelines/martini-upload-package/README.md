# Martini Package Upload with AWS CodePipeline

This Terraform stack configures an AWS CodePipeline for uploading Martini packages to a specified Martini instance. The pipeline zips packages from this repository and uploads them via the Martini API using a configurable shell script.

---

## Overview

The **martini-upload-package** pipeline:

- Uses GitHub (via CodeStar Connections) as the source repository.
- Triggers on changes to a configured branch.
- Runs an AWS CodeBuild project that:
  - Uses `terraform/buildspecs/martini-upload-package.yaml` as the buildspec.
  - Executes `terraform/scripts/upload_packages.sh`.
  - Zips packages from a configured directory (default: `packages`).
  - Filters packages using a regex pattern.
  - Uploads them to a remote Martini runtime using `BASE_URL` and `MARTINI_ACCESS_TOKEN`.
  - Optionally treats HTTP 504 as success and polls for package startup according to configured delay/timeout.

Configuration and secrets are provided via SSM Parameter Store and Terraform variables.

---

## Repository Structure

In this folder:

- `main.tf` – Wires up modules for IAM, S3, CloudWatch, SSM, CodeBuild, and CodePipeline.
- `variables.tf` – Input variables for the stack (see table below).
- `outputs.tf` – Exposes useful outputs such as the CodePipeline name, CodeBuild project name, and SSM parameter name.

Other referenced files:

- `../../buildspecs/martini-upload-package.yaml` – Buildspec used by CodeBuild.
- `../../scripts/upload_packages.sh` – Upload script executed by CodeBuild.
- Modules from `../../modules/*` – Shared components (cloudwatch, iam, s3, ssm, etc.).

---

## Requirements

- Terraform 1.3.0+
- AWS credentials with permissions to create:
  - CodePipeline, CodeBuild, S3, SSM, CloudWatch, IAM
- CodeStar **connection ARN** to the GitHub repository used as the pipeline source.
- A running Martini instance accessible from the build environment.

---

## Usage

Example usage:

```bash
cd terraform/pipelines/martini-upload-package

terraform init
terraform plan -var="pipeline_name=martini-upload-package" \
               -var="repository_name=your-org/your-repo" \
               -var="branch_name=main" \
               -var="connection_arn=arn:aws:codestar-connections:..." \
               -var="base_url=https://martini.example.com" \
               -var="martini_access_token=***" \
               -var="log_retention_days=14" \
               -var='tags={ Environment = "dev", Project = "martini" }'
terraform apply
```

You can set additional optional variables (such as `package_name_pattern` and polling-related variables) via `terraform.tfvars` or `-var` flags.

---

## Input Reference

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| pipeline_name | Pipeline name. | string | "martini-upload-package" | no |
| environment | Deployment environment (e.g., dev, staging, prod). | string | "dev" | no |
| aws_region | AWS region for deployment. | string | n/a | yes |
| repository_name | Full GitHub repository name (e.g., username/repo) | string | n/a | yes |
| branch_name | Branch name for CodePipeline source trigger. | string | "main" | no |
| buildspec_filename | Buildspec file used by CodeBuild. | string | "../buildspecs/martini-upload-package.yaml" | no |
| codestar_connection_arn | ARN of the AWS CodeStar Connection for GitHub. | string | n/a | yes |
| base_url | URL of the Martini runtime server. | string | n/a | yes |
| martini_access_token | OAuth token for the Martini API. | string | n/a | yes |
| async_upload | Enable async upload mode. | bool | false | no |
| success_check_delay | Delay (seconds) between polling attempts. | number | 30 | no |
| success_check_timeout | Max number of polling attempts. | number | 6 | no |
| log_retention_days | CloudWatch log retention period. | number | 90 | no |
| kms_key_arn | KMS key ARN for encryption. | string | null | no |
| tags | Additional tags applied to resources. | map(string) | {} | no |

---

## SSM Parameter Content

The SSM parameter referenced by `parameter_name` typically contains JSON used by the upload script. Its keys mirror the CodeBuild environment expected by `upload_packages.sh`, for example:

- `BASE_URL`
- `MARTINI_ACCESS_TOKEN`
- `PACKAGE_NAME_PATTERN`
- `PACKAGE_DIR`
- `ASYNC_UPLOAD`
- `SUCCESS_CHECK_TIMEOUT`
- `SUCCESS_CHECK_DELAY`
- `SUCCESS_CHECK_PACKAGE_NAME`

Terraform can either:
- Pass these values directly as plain environment variables, or
- Store them in SSM and have the buildspec retrieve them at runtime.

---

## Notes

- **Buildspec and Script**: This stack assumes that the `buildspec_file` and `upload_packages.sh` exist in the repository referenced by `repository_name`.
- **Security**:
  - Secrets such as `martini_access_token` should be treated as sensitive input and stored in SSM as `SecureString` where appropriate.
- **Monitoring & Debugging**:
  - CloudWatch log groups are created via shared modules.
  - Inspect build and pipeline logs in the AWS console to troubleshoot failures.
