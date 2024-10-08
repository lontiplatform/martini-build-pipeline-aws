# Martini Build Pipeline with AWS CodePipeline

This Martini Build Pipeline, utilizing AWS CodePipeline, provides two distinct build processes designed for flexibility and control over the deployment of Martini Server Runtime and its packages.

### Build Options:
1. **`martini-build-image.yaml`**
This buildspec builds a Docker image that bundles the Martini Server Runtime with your Martini Packages, allowing you to manage both the runtime version and the packages within a single deployment. This approach ensures that you have full control over the deployment environment, making it ideal for scenarios where both runtime and package versions need to be tightly controlled.

2. **`martini-upload-package.yaml`**
This buildspec focuses on deploying your Martini packages to an existing Martini Server Runtime instance. This method requires deploying only the packages, keeping the runtime instance unchanged, which is a streamlined option for environments where the runtime remains consistent but packages need frequent updates. 

If you need to migrate from AWS CodeCommit to another Git provider such as GitHub, follow this guide: [How to migrate your AWS CodeCommit repository to another Git provider](https://aws.amazon.com/blogs/devops/how-to-migrate-your-aws-codecommit-repository-to-another-git-provider/).


## Environment Variables

The variables listed below are used in the buildspec when configuring your CI/CD pipeline or running your pipeline. These are environment variables set in AWS Parameter Store for secure storage and easy retrieval during pipeline execution. This ensures that sensitive information, such as credentials and configuration settings, is protected and dynamically accessible.

| **Variable Name**             | **Required** | **Description**                                                                                                         |
|-------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------|
| `MARTINI_VERSION`             | Yes          |The version of the Martini runtime to be used when building the Docker image. If not provided (null), it defaults to LATEST, but also supports explicit values of LATEST.                                           |
| `AWS_REGION`                  | Yes          | The AWS region where your ECR repository is located.                                                                    |
| `AWS_ACCOUNT_ID`              | Yes          | The AWS account ID where the ECR repository is hosted.                                                                  |
| `ECR_REPO_NAME`               | Yes          | The name of the ECR repository where the Docker image will be pushed.                                                   |
| `BASE_URL`                    | Yes          | The base URL for the API endpoint where packages will be uploaded and requests are made.                                |
| `MARTINI_USER_NAME`           | Yes          | The username for authentication with the Martini API.                                                                   |
| `MARTINI_USER_PASSWORD`       | Yes          | The password for authentication with the Martini API.                                                                   |
| `${PARAMETER_NAME}`           | Yes          | The parameter store parameter name that is being used to fetch environment variables.                                   |

## Running the Pipeline

By default, a pipeline starts automatically when it is created and any time a change is made in it's source repository. However, you might want to rerun the most recent revision through the pipeline a second time. You can use the CodePipeline console or the AWS CLI and start-pipeline-execution command to manually rerun the most recent revision through your pipeline.

To start the pipeline execution, use the following command:

```bash
aws codepipeline start-pipeline-execution --name pipeline-name
```

You can also use this pipeline as an extension of your pipeline and this can be achieved by adding the code snippet above in the buildspec of your pipeline.