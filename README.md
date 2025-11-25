# Martini CI/CD Pipeline With AWS CodePipeline

This repository contains the full CI/CD implementation for Martini applications using **AWS CodePipeline**, **AWS CodeBuild**, and **Terraform**. It consolidates buildspecs, helper scripts, Terraform modules, and pipeline stacks into a single repository.

There are two pipelines:

1. **Build Martini Runtime Image** – builds a Docker image that bundles a specific Martini runtime version and one or more packages, and pushes it to Amazon ECR.
2. **Upload Martini Packages** – zips one or more Martini packages from this repository and uploads them to a running Martini instance via the Martini API.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── precommit.yml        # GitHub Actions workflow to run pre-commit checks
├── .pre-commit-config.yaml      # Local linting / formatting hooks
├── packages/
│   └── sample-package/          # Example Martini package layout
│       ├── code/
│       └── conf/
├── terraform/
│   ├── buildspecs/              # CodeBuild buildspec YAML files
│   ├── modules/                 # Reusable Terraform modules (cloudwatch, ecr, iam, s3, ssm, etc.)
│   ├── pipelines/
│   │   ├── martini-build-image/ # Pipeline stack for building Docker images
│   │   └── martini-upload-package/ # Pipeline stack for uploading packages
│   └── scripts/                 # Supporting artifacts (Dockerfile, upload script)
└── .yamllint                    # YAML linting config
```

- The **Terraform root** and **pipeline stacks** are documented under `terraform/README.md` and the two pipeline READMEs.
- The **sample package** exists for testing only; it is not a production package.

---

## Workflows

### 1. Build Martini Runtime Image

The **martini-build-image** pipeline:

- Uses `terraform/buildspecs/martini-build-image.yaml` as the buildspec.
- Uses `terraform/scripts/dockerfile` to define the runtime image.
- Checks out this GitHub repository via CodeStar Connections.
- Invokes AWS CodeBuild to:
  - Download Martini runtime (based on a configured version).
  - Bundle one or more packages from `packages/`.
  - Build and push an image to ECR.
- Stores logs in CloudWatch and artifacts in S3.

### 2. Upload Martini Packages

The **martini-upload-package** pipeline:

- Uses `terraform/buildspecs/martini-upload-package.yaml` as the buildspec.
- Uses `terraform/scripts/upload_packages.sh` to:
  - Zip packages from `packages/`.
  - Filter packages with a regex (`PACKAGE_NAME_PATTERN`).
  - Upload them to a remote Martini runtime (`BASE_URL`) via the API.
  - Optionally poll for successful startup using configurable delay/timeout values.
- Uses SSM Parameter Store to inject configuration and secrets into CodeBuild.

---

## Requirements

- **Terraform**: v1.3.0+
- **AWS**:
  - AWS CLI configured with access to create CodePipeline, CodeBuild, ECR, S3, SSM, IAM, and CloudWatch.
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
   For each pipeline under `terraform/pipelines/...`, prepare:
   - `terraform.tfvars` (or equivalent) with values such as:
     - `repository_name`
     - `branch_name`
     - `connection_arn`
     - `pipeline_name`
     - `log_retention_days`
     - Any workflow-specific settings.

5. **Deploy a pipeline stack with Terraform**
   Example for the upload-package pipeline:
   ```bash
   cd terraform/pipelines/martini-upload-package

   terraform init
   terraform plan
   terraform apply
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

The pipelines rely on SSM Parameter Store to provide configuration to CodeBuild via a parameter that contains JSON.

At a minimum, ensure the following keys exist in the JSON (for the upload pipeline):

- `BASE_URL`
- `MARTINI_ACCESS_TOKEN`
- `PACKAGE_NAME_PATTERN` (optional)
- `PACKAGE_DIR` (optional, defaults to `packages`)
- `ASYNC_UPLOAD` (optional)
- `SUCCESS_CHECK_TIMEOUT` (optional)
- `SUCCESS_CHECK_DELAY` (optional)
- `SUCCESS_CHECK_PACKAGE_NAME` (optional)

The **upload pipeline module** exposes variables such as `parameter_name`, `package_dir`, `package_name_pattern`, `async_upload`, and polling-related settings to control this behaviour.

---

## GitHub Actions and pre-commit

- `.github/workflows/precommit.yml` runs the same checks defined in `.pre-commit-config.yaml` on each push or pull request.
- Typical checks include:
  - Terraform formatting / validation
  - YAML linting
  - Basic shell / code style checks (depending on configured hooks)

This ensures changes to Terraform, buildspecs, and scripts remain consistent.

---

## References

- Martini Documentation
- AWS CodePipeline Documentation
- AWS CodeBuild Documentation
- Terraform Documentation
