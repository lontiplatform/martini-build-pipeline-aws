# Martini CI/CD Pipeline With AWS CodePipeline

This repository contains a complete CI/CD implementation for Martini applications using **AWS CodePipeline**, **AWS CodeBuild**, and **Terraform/OpenTofu**. It consolidates buildspecs, helper scripts, Terraform configurations, and pipeline stacks into a unified structure.

There are two pipelines:

1. **Build Martini Runtime Image** – builds a Docker image that bundles a Martini runtime version and project packages, and pushes it to ECR.
2. **Upload Martini Packages** – zips Martini packages from this repository and uploads them to a running Martini instance via the Martini API.

Both pipelines are fully automated, GitHub-triggered, secure, and validated via pre-commit and CI.

---

## Why Terraform *and* OpenTofu?

This repository supports both **Terraform** and **OpenTofu**. OpenTofu is the community-driven, fully open-source continuation of Terraform after HashiCorp’s license change.

We use OpenTofu because:

- It is **fully open-source (MPL 2.0)**.
- It remains **100% compatible** with existing Terraform `.tf` code.
- It avoids vendor lock-in and future licensing issues.
- Our **pre-commit** and **CI workflows** already integrate with it.
- It ensures long-term maintainability of the infrastructure stack.

You can use either CLI:

```bash
terraform init   # or
tofu init

terraform plan   # or
tofu plan

terraform apply  # or
tofu apply
```

---

## Repository Structure

```text
.
├── .checkov.yaml
├── .github/
│   └── workflows/
│       └── precommit.yml
├── .gitignore
├── LICENSE
├── packages/
│   └── sample-package/
│       ├── code/
│       │   └── sample_package/
│       └── conf/
│           ├── dependency.xml
│           └── package.xml
├── .pre-commit-config.yaml
├── .yamllint
├── README.md
└── terraform/
    ├── README.md
    ├── buildspecs/
    │   ├── martini-build-image.yaml
    │   └── martini-upload-package.yaml
    ├── modules/
    │   ├── iam_codebuild/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── iam_codepipeline/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── pipelines/
    │   ├── martini-build-image/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   ├── README.md
    │   │   └── .terraform-docs.yml
    │   └── martini-upload-package/
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── README.md
    │       └── .terraform-docs.yml
    └── scripts/
        ├── Dockerfile
        └── upload_packages.sh
```

- **Terraform layout** and pipeline stacks are documented under `terraform/README.md` and the two pipeline READMEs.
- The **sample package** is for testing only; it is not a production package.

---

## Workflows

### 1. Build Martini Runtime Image

The **martini-build-image** pipeline:

- Uses `terraform/buildspecs/martini-build-image.yaml` as the buildspec.
- Uses `terraform/scripts/Dockerfile` to define the runtime image.
- Checks out this GitHub repository via CodeStar Connections.
- Invokes AWS CodeBuild to:
  - Download a specific Martini runtime version.
  - Bundle one or more packages from `packages/`.
  - Build and push an image to ECR.
- Stores logs in CloudWatch and artifacts (if any) in S3.

See `terraform/pipelines/martini-build-image/README.md` for full Inputs and usage.

### 2. Upload Martini Packages

The **martini-upload-package** pipeline:

- Uses `terraform/buildspecs/martini-upload-package.yaml` as the buildspec.
- Uses `terraform/scripts/upload_packages.sh` to:
  - Zip packages from the `packages/` directory.
  - Filter packages with a regex (`package_name_pattern`).
  - Upload them to a remote Martini runtime (`BASE_URL`) via the API.
  - Optionally poll for successful startup using configurable delay/timeout values.
- Uses SSM Parameter Store to inject configuration and secrets into CodeBuild.

See `terraform/pipelines/martini-upload-package/README.md` for full Inputs and usage.

---

## Requirements

- **Terraform or OpenTofu**: v1.3.0+ compatible
- **AWS**:
  - AWS CLI configured with access to create CodePipeline, CodeBuild, ECR, S3, SSM, IAM, and CloudWatch resources.
  - An AWS account and region where pipelines will run.
- **GitHub**:
  - A GitHub repository that will act as the **source** for the pipelines (usually this one).
  - An AWS **CodeStar Connection ARN** to that GitHub repository (configured manually in the AWS console).
- **Local tools** (for development):
  - `pre-commit` installed.
  - Python and any tools required by `.pre-commit-config.yaml`.

---

## Local Development Workflow

A typical flow when working with this repository:

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd <repo>
   ```

2. **Install pre-commit hooks**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

3. **Run checks locally (optional but recommended)**
   ```bash
   pre-commit run --all-files
   ```

4. **Configure variables for the pipeline stack(s)**
   For each pipeline under `terraform/pipelines/...`, prepare a `terraform.tfvars` (or equivalent) with values such as:
   - `repository_name`
   - `branch_name`
   - `connection_arn`
   - `pipeline_name`
   - `log_retention_days`
   - Any workflow-specific settings (e.g., `base_url`, `martini_access_token`).

5. **Deploy a pipeline stack**
   Example for the upload-package pipeline:
   ```bash
   cd terraform/pipelines/martini-upload-package

   terraform init   # or: tofu init
   terraform plan   # or: tofu plan
   terraform apply  # or: tofu apply
   ```

   Similarly, use `terraform/pipelines/martini-build-image` for the image build pipeline.

6. **Trigger a pipeline run**

   Once the stack is applied:
   - Push a commit to the configured GitHub branch, or
   - Manually trigger the pipeline via the AWS console, or
   - Use the AWS CLI:
     ```bash
     aws codepipeline start-pipeline-execution --name <pipeline-name>
     ```

---

## SSM Parameter Store Configuration

The pipelines rely on SSM Parameter Store to provide configuration to CodeBuild via parameters that contain JSON.

For the **upload pipeline**, typical keys include:

- `BASE_URL`
- `MARTINI_ACCESS_TOKEN`
- `PACKAGE_NAME_PATTERN` (optional)
- `PACKAGE_DIR` (optional, defaults to `packages`)
- `ASYNC_UPLOAD` (optional)
- `SUCCESS_CHECK_TIMEOUT` (optional)
- `SUCCESS_CHECK_DELAY` (optional)
- `SUCCESS_CHECK_PACKAGE_NAME` (optional)

For the **build-image pipeline**, the SSM parameter (commonly named `BUILD_IMAGE_PARAMETER`) may include keys such as:

- `martini_version`
- Additional build-time flags or configuration

The exact variable names and parameter wiring are documented in each pipeline README.

---

## GitHub Actions and pre-commit

- `.github/workflows/precommit.yml` runs the same checks defined in `.pre-commit-config.yaml` on each push or pull request.
- Typical checks include:
  - Terraform/OpenTofu formatting and validation
  - Checkov security scanning
  - YAML linting
  - Shell or other style checks, depending on configured hooks

This ensures changes to Terraform, buildspecs, and scripts remain consistent.

---

## References

- [Martini Documentation](https://developer.lonti.com/docs/martini/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [OpenTofu Documentation](https://opentofu.org/)
