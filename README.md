# Martini Build Pipeline with AWS CodePipeline

This repository enables robust CI/CD workflows for Martini applications using **AWS CodePipeline** and **AWS CodeBuild**. It supports both building Docker images of the Martini Server Runtime and uploading application packages to existing Martini instances.

##  Repository Overview

### Martini Build Pipeline AWS
> GitHub: [martini-build-pipeline-aws](https://github.com/lontiplatform/martini-build-pipeline-aws)

This repository contains `buildspec` YAML files and helper scripts for two distinct Martini workflows:

#### 1. `martini-build-image.yaml`
Builds a Docker image that bundles:
- Martini Server Runtime (from a specific version)
- Application packages

The image is pushed to Amazon ECR for deployment.

Supporting file:
- **`Dockerfile`**  Defines how the Martini runtime image is built and bundled with application packages.

#### 2. `martini-upload-package.yaml`
Zips and uploads application packages to a live Martini runtime instance via the Martini API. Supports async mode and polling to verify startup.

Supporting file:
- **`upload_packages.sh`**  A reusable shell script that handles package filtering, upload, and optional startup status polling.

---

##  Cloning This Repository

```bash
git clone https://github.com/lontiplatform/martini-build-pipeline-aws.git
```

---

##  Environment Configuration

Both buildspec files rely on environment parameters retrieved from **AWS SSM Parameter Store**. These parameters can be managed via:

- Terraform (recommended)
- Manual SSM creation

To inspect or test SSM values locally:

```bash
PARAMETER_NAME="${PARAMETER_NAME:-martini-upload-package}"
echo "Using Parameter Store key: $PARAMETER_NAME"
PARAMETER=$(aws ssm get-parameter --name "$PARAMETER_NAME" --with-decryption --query "Parameter.Value" --output text)
```

Terraform modules define SSM configuration:

- [`martini-upload-package` module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-upload-package)
- [`martini-build-image` module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-build-image)

---

## Environment Variables

Ensure the following variables are defined via SSM Parameter Store or injected in CodeBuild:

| Variable | Required | Description |
|----------|----------|-------------|
| `PARAMETER_NAME` | Yes | The name of the SSM parameter that holds the configuration JSON used by the pipeline. |

---

### Image Build Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `MARTINI_VERSION` | No | The version of the Martini runtime to be used when building the Docker image. If not provided, it defaults to LATEST. |
| `ECR_REPO_NAME` | Yes | ECR repository name. |

---

### Package Upload Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `BASE_URL` | Yes | Martini instance base URL. |
| `MARTINI_ACCESS_TOKEN` | Yes | Authentication token for Martini API. |
| `PACKAGE_NAME_PATTERN` | No | Regex pattern to filter packages. |
| `PACKAGE_DIR` | No | Directory to scan for packages (default: `packages`). |
| `ASYNC_UPLOAD` | No | If true, tolerates 504 responses and uses polling. |
| `SUCCESS_CHECK_TIMEOUT` | No | Max polling attempts for startup verification. |
| `SUCCESS_CHECK_DELAY` | No | Delay between polling attempts (in seconds). |
| `SUCCESS_CHECK_PACKAGE_NAME` | No | Specific package to verify startup status (used during polling). |

---

## Running the Pipeline

You can start a pipeline execution using the AWS CLI:

```bash
aws codepipeline start-pipeline-execution --name pipeline-name
```

This command can be integrated into GitHub Actions or other CI/CD systems for automation.

---

## Additional Resources

- [Martini Documentation](https://developer.lonti.com/docs/martini/v1/)
- [AWS CodePipeline Docs](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Docs](https://docs.aws.amazon.com/codebuild/)
- [AWS ECR Docs](https://docs.aws.amazon.com/ecr/)
