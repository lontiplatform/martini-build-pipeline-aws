# Martini Build Image Pipeline

This Terraform/OpenTofu stack provisions an AWS CodePipeline and CodeBuild workflow that builds a Martini runtime Docker image bundled with one or more Martini packages, and then pushes it to Amazon ECR.

---

## Overview

The **martini-build-image** pipeline:

- Uses GitHub as the source (via an AWS CodeStar Connection).
- Triggers on commits to a configured branch.
- Runs an AWS CodeBuild project that:
  - Uses the `martini-build-image.yaml` buildspec.
  - Uses `terraform/scripts/Dockerfile` to build the Martini image.
  - Injects configuration from SSM Parameter Store (for example, Martini version and additional flags).
  - Builds and pushes a Docker image to an ECR repository.
- Stores logs in CloudWatch and artifacts in S3.
- Uses a dedicated SSM parameter (commonly `BUILD_IMAGE_PARAMETER`) to provide build-time JSON configuration to CodeBuild.

---

## Repository Structure

Inside this pipeline folder:

- `main.tf` – Wiring for IAM, S3, CloudWatch, SSM, ECR, CodeBuild, and CodePipeline modules.
- `variables.tf` – Inputs that configure the pipeline.
- `outputs.tf` – Exposes pipeline and CodeBuild details (ARNs, names, parameter names).
- `.terraform-docs.yml` – Configuration for auto-generating the Inputs table below.

Referenced artifacts:

- `../../buildspecs/martini-build-image.yaml` – Buildspec executed by CodeBuild.
- `../../scripts/Dockerfile` – Dockerfile used to build the Martini runtime image.
- `../../modules/*` – Local IAM modules.

---

## Requirements

- **Terraform or OpenTofu**: v1.3.0+
- **AWS**:
  - Permissions to create CodePipeline, CodeBuild, ECR, S3, SSM parameters, IAM roles, and CloudWatch log groups.
- **GitHub**:
  - A manually-created AWS CodeStar **Connection ARN** pointing to this repository.
- **pre-commit** (recommended during development).

---

## Usage

Example deployment:

```bash
cd terraform/pipelines/martini-build-image

terraform init   # or: tofu init

terraform plan  -var="pipeline_name=martini-build-image" \
                -var="repository_name=your-org/your-repo" \
                -var="branch_name=main" \
                -var="connection_arn=arn:aws:codestar-connections:..." \
                -var="ecr_repo_name=martini-runtime" \
                -var="log_retention_days=14" \
                -var='tags={ Environment = "dev", Project = "martini" }'

terraform apply  # or: tofu apply
```

You can also provide these variables via terraform.tfvars.

After applying:

- A CodePipeline and CodeBuild project are created.
- The pipeline triggers when commits are pushed to the configured branch.
- Any updates to the Dockerfile or buildspec will initiate a new image build.

---

## Input Reference

> **Note:** This section is automatically generated using `terraform-docs`.
> Do not edit manually.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for deployment. | `string` | n/a | yes |
| <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name) | Branch name for CodePipeline source trigger. | `string` | `"main"` | no |
| <a name="input_buildspec_filename"></a> [buildspec\_filename](#input\_buildspec\_filename) | The buildspec file for the CodeBuild project. | `string` | `"terraform/buildspecs/martini-build-image.yaml"` | no |
| <a name="input_codestar_connection_arn"></a> [codestar\_connection\_arn](#input\_codestar\_connection\_arn) | ARN of the AWS CodeStar Connection for GitHub. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g., dev, staging, prod). | `string` | `"dev"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for encryption of logs, S3, SSM, and artifacts. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Retention period in days for CloudWatch log groups. | `number` | `90` | no |
| <a name="input_martini_version"></a> [martini\_version](#input\_martini\_version) | Version of the Martini runtime to include in the Docker image. | `string` | `"latest"` | no |
| <a name="input_pipeline_name"></a> [pipeline\_name](#input\_pipeline\_name) | Pipeline name, used for naming resources. | `string` | `"martini-build-image"` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Full GitHub repository name (e.g., username/repo). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of additional tags applied to all resources. | `map(string)` | `{}` | no |
<!-- END_TF_DOCS -->

---

## Notes

### Buildspec & Dockerfile

The pipeline expects the following to exist in the source repository:

- `terraform/buildspecs/martini-build-image.yaml`
- `terraform/scripts/Dockerfile`

These define how the Docker image is built inside CodeBuild.

### SSM Parameter Store Configuration

The pipeline typically uses an SSM parameter (e.g., `BUILD_IMAGE_PARAMETER`) to pass JSON configuration into CodeBuild. Example keys:

- `martini_version`
- Any additional configuration required by the buildspec.

### Monitoring & Debugging

CloudWatch log groups for CodePipeline and CodeBuild are created automatically.
Use these logs to troubleshoot pipeline executions and build failures.
