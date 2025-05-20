# Martini Build Pipeline with AWS CodePipeline

This Martini Build Pipeline leverages AWS CodePipeline and CodeBuild to provide robust Continuous Integration and Continuous Deployment (CI/CD) workflows for Martini applications. It offers flexibility and control over deploying the Martini Server Runtime and its packages, whether you are building Docker images or deploying packages to existing instances.

## Repositories Overview

### Martini Build Pipeline AWS ([GitHub Link](https://github.com/lontiplatform/martini-build-pipeline-aws))
This repository contains `buildspec` files and CI/CD automation scripts:

1. **`martini-build-image.yaml`**: Builds a Docker image bundling the Martini Server Runtime and packages, then pushes it to Amazon ECR.
   - **`Dockerfile`**: Defines how the Martini runtime image is built and bundled with application packages as part of the `martini-build-image` pipeline.

2. **`martini-upload-package.yaml`**: Packages and uploads Martini applications to an existing runtime instance, ensuring streamlined updates.
   - **`upload_packages.sh`**: Reusable script that handles dynamic configuration, package zipping, validation, upload, and polling as part of the `martini-upload-package` pipeline.

### Cloning the Repository

```bash
git clone https://github.com/lontiplatform/martini-build-pipeline-aws.git
```

### Updating the Buildspec Files
The `buildspec` files rely on environment parameters stored in AWS SSM Parameter Store. These parameters can be customized via Terraform or passed manually using `${PARAMETER_NAME}`.

```bash
PARAMETER_NAME="${PARAMETER_NAME:-martini-upload-package}"
echo "Using Parameter Store key: $PARAMETER_NAME"
PARAMETER=$(aws ssm get-parameter --name "$PARAMETER_NAME" --with-decryption --query "Parameter.Value" --output text)
```

Parameter names are defined in the corresponding Terraform modules:
- [martini-upload-package module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-upload-package)
- [martini-build-image module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-build-image)

## Environment Variables

Ensure the following variables are defined via SSM Parameter Store or injected in CodeBuild:

| Variable | Required | Description |
|----------|----------|-------------|
| `PARAMETER_NAME` | Yes | The name of the SSM parameter that holds the configuration JSON used by the pipeline. |

### Image Build Parameters
| Parameter | Required | Description |
|-----------|----------|-------------|
| `MARTINI_VERSION` | No | The version of the Martini runtime to be used when building the Docker image. If not provided, it defaults to LATEST. |
| `AWS_REGION` | Yes | AWS region for ECR. |
| `AWS_ACCOUNT_ID` | Yes | AWS account ID for ECR. |
| `ECR_REPO_NAME` | Yes | ECR repository name. |

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

## Running the Pipeline

To manually trigger the pipeline:

```bash
aws codepipeline start-pipeline-execution --name pipeline-name
```

This command can be integrated into GitHub Actions or other CI/CD systems for automation.

## Additional Resources

- [Martini Documentation](https://developer.lonti.com/docs/martini/v1/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
