# Terraform Layout

This directory contains all Terraform / OpenTofu configuration used to provision Martini CI/CD pipelines on AWS. Pipelines are defined under `terraform/pipelines/` and can be deployed independently.

You typically run `terraform` (or `tofu`) from within a specific pipeline directory.

---

## Folder Overview

### `buildspecs/`

Buildspec YAML files executed by AWS CodeBuild:

- `martini-build-image.yaml`
- `martini-upload-package.yaml`

Each pipeline references its buildspec via input variables (e.g., `buildspec_file`).

---

### `modules/`

Local IAM modules shared by both pipelines:

- `iam_codebuild/` – IAM roles and policies for CodeBuild projects.
- `iam_codepipeline/` – IAM roles and policies for CodePipeline.

Other infrastructure components (S3 artifact buckets, CloudWatch log groups, etc.) are composed directly in the pipeline stacks using official Terraform Registry modules, not separate local modules.

---

### `pipelines/`

Deployable pipeline stacks. Each folder is an independent Terraform / OpenTofu configuration:

- `martini-build-image/`
  Provisions a CodePipeline + CodeBuild workflow for building Martini runtime images and pushing them to ECR.

- `martini-upload-package/`
  Provisions a CodePipeline + CodeBuild workflow for zipping and uploading Martini packages to an existing Martini runtime.

Each pipeline folder includes:

- `main.tf` – Stack wiring (uses `modules/` and registry modules).
- `variables.tf` – Inputs and defaults.
- `outputs.tf` – Useful outputs (e.g., CodeBuild project name, CodePipeline name, SSM parameter name).
- `README.md` – Usage instructions and workflow overview.
- `.terraform-docs.yml` – Configuration for automatically generating the Inputs table in the README.

---

### `scripts/`

Helper artifacts referenced by the buildspecs:

- `Dockerfile`
  Used by the build-image pipeline to build the Martini runtime container image.

- `upload_packages.sh`
  Used by the upload-package pipeline to zip, filter, upload packages, and optionally poll the runtime for startup success.

Terraform / OpenTofu does not execute these scripts directly; they are invoked by CodeBuild during pipeline execution.

---

## Running Terraform / OpenTofu

To deploy a pipeline:

1. Change into the target pipeline directory:
   ```bash
   cd terraform/pipelines/martini-build-image
   # or
   cd terraform/pipelines/martini-upload-package
   ```

2. Provide required variables via `terraform.tfvars`, environment variables, or `-var` flags.

3. Run:

   ```bash
   terraform init   # or: tofu init
   terraform plan   # or: tofu plan
   terraform apply  # or: tofu apply
   ```

You can deploy one or both pipelines depending on your needs.

---

## Extending the Layout

To add a new pipeline:

1. Create a new folder under `terraform/pipelines/`.
2. Reuse the IAM modules under `terraform/modules/` where appropriate.
3. Use Terraform Registry modules for infrastructure (S3, CloudWatch, etc.), consistent with existing stacks.
4. Add any new buildspecs or scripts under:
   - `terraform/buildspecs/`
   - `terraform/scripts/`
5. Add a README in the new pipeline folder following this style:
   - Short intro
   - Repository structure for that pipeline
   - Requirements
   - How to run Terraform / OpenTofu
   - Auto-generated Inputs section (`terraform-docs` with `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->`)
