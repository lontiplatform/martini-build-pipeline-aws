# Terraform Layout

This folder contains all Terraform configuration related to the Martini CI/CD pipelines. It is organized into reusable modules and thin pipeline stacks.

Typically, you run `terraform` from inside one of the pipeline directories under `terraform/pipelines/`.

---

## Folder Overview

### `buildspecs/`

Buildspec YAML files consumed by CodeBuild:

- `martini-build-image.yaml`
- `martini-upload-package.yaml`

These files define how CodeBuild should build the Docker image or upload packages. They are referenced via the `buildspec_file` variable in the pipeline modules.

---

### `modules/`

Reusable Terraform modules shared by both pipelines, for example:

- `cloudwatch/` – CloudWatch log groups and retention.
- `ecr/` – ECR repositories for images (used by the build-image pipeline).
- `iam_codebuild/` – IAM roles and policies for CodeBuild.
- `iam_codepipeline/` – IAM roles and policies for CodePipeline.
- `s3/` – S3 buckets for artifacts.
- `ssm/` – SSM parameters for pipeline configuration.

Pipeline stacks under `pipelines/` compose these building blocks rather than defining resources directly.

---

### `pipelines/`

Top-level pipeline stacks. Each folder is a self-contained Terraform configuration you can deploy independently:

- `martini-build-image/`
  - Provisions a CodePipeline + CodeBuild + ECR workflow for building Martini runtime images.
- `martini-upload-package/`
  - Provisions a CodePipeline + CodeBuild workflow for zipping and uploading packages to a running Martini instance.

Each pipeline folder contains:

- `main.tf` – Stack wiring that uses modules from `../modules`.
- `variables.tf` – Input variables and descriptions.
- `outputs.tf` – Useful outputs (e.g., CodeBuild project name, CodePipeline name, SSM parameter names).

Refer to the README inside each pipeline folder for usage and inputs.

---

### `scripts/`

Helper artifacts referenced by the buildspecs:

- `dockerfile`
  - Used by the build-image pipeline to build a Martini runtime container image.
- `upload_packages.sh`
  - Used by the upload-package pipeline to zip, filter, and upload packages and optionally poll the runtime for startup success.

These files are not executed by Terraform itself; Terraform configures CodeBuild to use them.

---

## Running Terraform

For each pipeline:

1. Change into the pipeline folder:
   ```bash
   cd terraform/pipelines/martini-build-image
   # or
   cd terraform/pipelines/martini-upload-package
   ```

2. Prepare variable values (`terraform.tfvars`, environment variables, or CLI `-var` flags).

3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

You can deploy one or both pipelines depending on your needs.

---

## Extending the Layout

To add a new pipeline:

1. Create a new folder under `terraform/pipelines/`.
2. Reuse existing modules under `terraform/modules/` where possible.
3. Reference any new buildspecs or scripts from `terraform/buildspecs/` and `terraform/scripts/`.
4. Add a small README in the new pipeline folder following the existing style:
   - Short intro
   - Repository structure
   - Requirements
   - How to run Terraform
   - Inputs table (if applicable)
