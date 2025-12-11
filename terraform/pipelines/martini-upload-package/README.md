# Martini Package Upload Pipeline

This Terraform/OpenTofu stack provisions an AWS CodePipeline and CodeBuild workflow that zips Martini packages from this repository and uploads them to a running Martini instance via the Martini API.

---

## Overview

The **martini-upload-package** pipeline:

- Uses GitHub as the source, via an AWS CodeStar Connection.
- Triggers on commits to a configured branch.
- Executes an AWS CodeBuild project that:
  - Uses the `martini-upload-package.yaml` buildspec.
  - Runs `terraform/scripts/upload_packages.sh`.
  - Zips packages from a configured directory (default: `packages/`).
  - Filters packages using a regex (configured via Terraform).
  - Uploads packages to a remote Martini runtime using `BASE_URL` and `MARTINI_ACCESS_TOKEN`.
  - Optionally handles HTTP 504 as success (async upload mode).
  - Can poll the runtime for package startup using configurable delay and timeout settings.

Configuration and secrets are passed via SSM Parameter Store (commonly `UPLOAD_PACKAGE_PARAMETER`) and Terraform variables.

---

## Repository Structure

Inside this pipeline folder:

- `main.tf` – Wires up IAM, S3, CloudWatch, SSM, CodeBuild, and CodePipeline modules.
- `variables.tf` – Inputs that configure the pipeline.
- `outputs.tf` – Exposes the CodePipeline name, CodeBuild project name, and SSM parameter name.
- `.terraform-docs.yml` – Configuration for auto-generating the Inputs table below.

Referenced artifacts:

- `../../buildspecs/martini-upload-package.yaml` – Buildspec used by CodeBuild.
- `../../scripts/upload_packages.sh` – Script executed by CodeBuild to zip, filter, upload, and optionally poll.
- `../../modules/*` – Local IAM modules.

---

## Requirements

- **Terraform or OpenTofu**: v1.11.0+
- **AWS**:
  - Permissions to create CodePipeline, CodeBuild, S3, SSM, IAM roles, and CloudWatch log groups.
- **GitHub**:
  - A CodeStar **Connection ARN** to the GitHub repository used as the pipeline source.
- **Networking**:
  - A running Martini instance (`base_url`) accessible from the CodeBuild environment.

---

## Usage

Example deployment:

```bash
cd terraform/pipelines/martini-upload-package

terraform init   # or: tofu init

terraform plan  -var="pipeline_name=martini-upload-package" \
                -var="repository_name=your-org/your-repo" \
                -var="branch_name=main" \
                -var="connection_arn=arn:aws:codestar-connections:..." \
                -var="base_url=https://martini.example.com" \
                -var="martini_access_token=***" \
                -var="log_retention_days=14" \
                -var='tags={ Environment = "dev", Project = "martini" }'

terraform apply  # or: tofu apply
```

You can set additional optional variables (such as package_name_pattern and polling-related variables) via terraform.tfvars or -var flags.

After applying:

- A CodePipeline and CodeBuild project are created for uploads.
- The pipeline triggers when commits are pushed to the configured branch.
- Any changes to packages, the buildspec, or `upload_packages.sh` will trigger a new upload run.
- Successful runs will zip, filter, and upload packages to the configured Martini runtime, and (if enabled) perform polling for startup success.

---

## Input Reference

> **Note:** This section is automatically generated using `terraform-docs`.
> Do not edit manually.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_async_upload"></a> [async\_upload](#input\_async\_upload) | Use async upload mode. If null, upload\_packages.sh default is used. | `bool` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for deployment. | `string` | n/a | yes |
| <a name="input_base_url"></a> [base\_url](#input\_base\_url) | URL of the target Martini runtime server to which packages are uploaded. | `string` | n/a | yes |
| <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name) | Branch name for CodePipeline source trigger. | `string` | `"main"` | no |
| <a name="input_buildspec_filename"></a> [buildspec\_filename](#input\_buildspec\_filename) | The buildspec file for the CodeBuild project. | `string` | `"terraform/buildspecs/martini-upload-package.yaml"` | no |
| <a name="input_codestar_connection_arn"></a> [codestar\_connection\_arn](#input\_codestar\_connection\_arn) | ARN of the AWS CodeStar Connection for GitHub. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g., dev, staging, prod). | `string` | `"dev"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for encrypting logs, S3 buckets, and SSM. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention period in days. | `number` | `90` | no |
| <a name="input_martini_access_token"></a> [martini\_access\_token](#input\_martini\_access\_token) | Long-lived OAuth token used to authenticate with the Martini runtime. | `string` | n/a | yes |
| <a name="input_pipeline_name"></a> [pipeline\_name](#input\_pipeline\_name) | Pipeline name | `string` | `"martini-upload-package"` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Full GitHub repository name (e.g., username/repo). | `string` | n/a | yes |
| <a name="input_success_check_delay"></a> [success\_check\_delay](#input\_success\_check\_delay) | Polling delay in seconds. If null, script default is used. | `number` | `null` | no |
| <a name="input_success_check_timeout"></a> [success\_check\_timeout](#input\_success\_check\_timeout) | Polling timeout count. If null, script default is used. | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources. | `map(string)` | `{}` | no |
<!-- END_TF_DOCS -->

---

## SSM Parameter Content

This pipeline uses an SSM parameter (typically named `UPLOAD_PACKAGE_PARAMETER`) to pass JSON configuration into CodeBuild. Common keys include:

- `BASE_URL`
- `MARTINI_ACCESS_TOKEN`
- `PACKAGE_NAME_PATTERN`
- `PACKAGE_DIR`
- `ASYNC_UPLOAD`
- `SUCCESS_CHECK_TIMEOUT`
- `SUCCESS_CHECK_DELAY`
- `SUCCESS_CHECK_PACKAGE_NAME`

The buildspec loads this JSON at runtime and exports the values as environment variables for `upload_packages.sh`.

---

## Notes

### Buildspec & Script

The pipeline expects the following to exist in the GitHub source repository:

- `terraform/buildspecs/martini-upload-package.yaml`
- `terraform/scripts/upload_packages.sh`

### Security

- `martini_access_token` should be treated as sensitive input.
- When stored in SSM, it should be a `SecureString`.

### Monitoring & Debugging

CloudWatch log groups are automatically created for both CodePipeline and CodeBuild.
Use these logs to diagnose upload failures, polling issues, or API errors.
