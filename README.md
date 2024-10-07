
# Martini Build Pipeline

This Martini Build Pipeline utilizes AWS CodePipeline. The repository includes two buildspec files for different build processes, such as building Docker images for the Martini runtime and uploading Martini packages. 

If you need to migrate from CodeCommit to another Git provider such as GitHub, follow this guide: [How to migrate your AWS CodeCommit repository to another Git provider](https://aws.amazon.com/blogs/devops/how-to-migrate-your-aws-codecommit-repository-to-another-git-provider/).


## Buildspec Files

- **`martini-build-image.yaml`**: Responsible for building and pushing Docker images for the Martini runtime to AWS ECR.
- **`martini-upload-package.yaml`**: Handles the zipping and uploading of Martini packages to the appropriate API endpoint.

## Getting Started

### Step 1: Choose the Appropriate Buildspec

Determine which buildspec file suits your project's requirements, and ensure it is placed in the root directory of your repository.

### Step 2: Update Environment Variables

Make sure sensitive information like tokens, credentials, and URLs are securely managed by passing them as environment variables during the build process. These should be set in your local environment or CI/CD pipeline configuration.

The necessary variables are stored in AWS Parameter Store, and the buildspec files retrieve them during the pre-build stage.

### Step 3: Execute the Build

Depending on your configuration, you can use the pipeline on its own or extend your own pipeline. To extend your pipeline, you can trigger the pipeline using the AWS CLI:

```bash
aws codepipeline start-pipeline-execution --name pipeline-name
```

## Environment Variables

The following environment variables are required for configuring this build process. These variables should be passed as environment variables when running the scripts or configuring your CI/CD pipeline:

| **Variable Name**             | **Required** | **Description**                                                                                                         |
|-------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------|
| `MARTINI_VERSION`             | Yes          | The version of the Martini runtime to be used when building the Docker image.                                           |
| `AWS_REGION`                  | Yes          | The AWS region where your ECR repository is located.                                                                   |
| `AWS_ACCOUNT_ID`              | Yes          | The AWS account ID where the ECR repository is hosted.                                                                 |
| `ECR_REPO_NAME`               | Yes          | The name of the ECR repository where the Docker image will be pushed.                                                  |
| `BASE_URL`                    | Yes          | The base URL for the API endpoint where packages will be uploaded and requests are made.                                |
| `MARTINI_USER_NAME`           | Yes          | The username for authentication with the Martini API.                                                                   |
| `MARTINI_USER_PASSWORD`       | Yes          | The password for authentication with the Martini API.                                                                   |
| `${PARAMETER_NAME}`           | Yes          | The parameter store parameter name that is being used to fetch environment variables.                                   |

## Input Descriptions

- **`DOCKER_IMAGE_NAME`**:  
  - Defines the Docker image name and tag in the format `repository:tag` used for building and tagging the image.  

- **`MARTINI_VERSION`**:  
  - Specifies the version of the Martini runtime included in the Docker image. It's passed as a build argument during the Docker build process.  

- **`BASE_URL`**:  
  - The remote Martini Runtime Server’s base URL, used for uploading packages.  

- **`MARTINI_USER_NAME`** and **`MARTINI_USER_PASSWORD`**:  
  - Credentials needed to authenticate with the Martini API, essential for obtaining OAuth tokens and interacting with the API for package uploads.  

- **`${PARAMETER_NAME}`**:  
  - Refers to the name of the parameter in AWS SSM Parameter Store used to fetch environment variables like `MARTINI_VERSION`, `AWS_REGION`, `AWS_ACCOUNT_ID`, and `ECR_REPO_NAME`.  
