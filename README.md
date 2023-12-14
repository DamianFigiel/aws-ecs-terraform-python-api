# AWS ECS, AWS CodeDeploy, Terraform, Python API

Complete solution to deploy API build into Docker image to AWS infrastructure created and managed by Terraform.

## How it works

1. Developer makes changes to `python-api`, opens PR, PR get approved and merged.
2. Once PR is merged, Github Action is triggered and new `python-api` image is pushed into AWS ECR repository.
3. New image in AWS ECR repository triggers AWS CodePipeline, which automaticlly deploys new API version to AWS ECS by using Blue/Green deployment strategy.
4. If automated health checks pass, release is successfull and old API version is removed.

## How to use it

# Prerequisites
- Clone repository into your own Github reposotory.
- Have AWS account.
- Create AWS user to use AWS CLI.
- Create AWS S3 bucket and AWS DynamoDB table to be used for Terraform State (https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- Put your S3, DynamoDB names and AWS region in `./terraform/backend.tf`

 -------------
# Step by step
1. Deploy infra
2. Push pipeline files
3. Push image


Create all needed AWS infrastructure with Terraform:
```

```


```Bash
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

3. Run `terraform init` in order to connect with backend and download plugins (providers).

4. Run `terraform workspace new dev` in order to create new workspace named `dev`.

5. Run `terraform plan -out=example.tfplan` in order to see infrastructure changes that are going to be applied.

6. Run `terrafrom apply example.tfplan` to apply changes.

7. (optional) If you want to destory infrastructure, run `terraform destory -auto-approve`.


