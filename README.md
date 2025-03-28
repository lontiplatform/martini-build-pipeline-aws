# Martini Build Pipeline with AWS CodePipeline

This Martini Build Pipeline leverages AWS CodePipeline to provide robust Continuous Integration and Continuous Deployment (CI/CD) workflows for Martini applications. It offers flexibility and control over deploying the Martini Server Runtime and its packages, whether you are building Docker images or deploying packages to existing instances.

## Repositories Overview

### Martini Build Pipeline AWS ([GitHub Link](https://github.com/lontiplatform/martini-build-pipeline-aws))

This repository contains `buildspec` files for AWS CodePipeline:

- **`martini-build-image.yaml`**: Builds a Docker image bundling the Martini Server Runtime and packages, then pushes it to Amazon ECR.
- **`martini-upload-package.yaml`**: Packages and uploads Martini applications to an existing runtime instance, ensuring streamlined updates.

### Cloning the Repository

Clone the required repository:

```bash
git clone https://github.com/lontiplatform/martini-build-pipeline-aws.git
```

### Updating the Buildspec Files

Replace `${PARAMETER_NAME}` with the actual parameter name in the following command from each buildspec file:

```bash
PARAMETER=$(aws ssm get-parameter --name "${PARAMETER_NAME}" --with-decryption --query "Parameter.Value" --output text)
```

These parameter names are defined in the `variable.tf` file from the Terraform modules:  
- [martini-upload-package module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-upload-package)  
- [martini-build-image module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/tree/main/martini-build-image)  

## Environment Variables

Ensure the following variables are set:

| Variable | Required | Description |
|-----------|----------|-------------|                                                                                                                                        
| `${PARAMETER_NAME}`      | Yes          | The parameter store parameter name used to fetch environment variables.

Ensure you use the correct parameter name defined in the `variable.tf` file from the [martini-build-image module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/blob/main/martini-build-image) and the [martini-upload-package module](https://github.com/lontiplatform/martini-build-pipeline-aws-terraform/blob/main/martini-upload-package). |

#### Image Building Specific
| Parameter | Required | Description |
|-----------|----------|-------------|
| `MARTINI_VERSION` | No | The version of the Martini runtime to be used when building the Docker image. If not provided (null), it defaults to LATEST but also supports explicit values. |
| `AWS_REGION` | Yes | AWS region for ECR |
| `AWS_ACCOUNT_ID` | Yes | AWS account ID for ECR |
| `ECR_REPO_NAME` | Yes | ECR repository name |

#### Package Upload Specific
| Parameter | Required | Description | Default Value |
|-----------|----------|-------------|---------------|
| `BASE_URL` | Yes | Martini instance base URL |
| `MARTINI_USER_NAME` | Yes | The username for authentication with the Martini API.|
| `MARTINI_USER_PASSWORD` | Yes | The password for authentication with the Martini API. |
| `CLIENT_ID` | No | OAuth client ID | "TOROMartini" |
| `CLIENT_SECRET` | Yes | OAuth client secret | - |


## Running the Pipeline

To manually trigger the pipeline:

```bash
aws codepipeline start-pipeline-execution --name pipeline-name
```

This command can also be integrated into your CI/CD workflow for automated pipeline execution.

## Additional Resources

- [Martini Documentation](https://developer.lonti.com/docs/martini/v1/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)