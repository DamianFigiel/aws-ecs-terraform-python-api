# Terraform Sample Repository

Terraform managed infrastructure sample. Deploying simple VPC.

## How to use

1. Create S3 bucket for remote state file and dynamodb for remote state lock. Put their names into backend.tf file.

2. Set environment variables that are required to communicate with AWS.

```Bash
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

3. Run `terraform init` in order to connect with backend and download plugins (providers).

4. Run `terraform workspace new dev` in order to create new workspace named `dev`.

5. Run `terraform plan -out=example.tfplan` in order to see infrastructure changes that are going to be applied.

6. Run `terrafrom apply example.tfplan` to apply changes.

7. (optional) If you want to destory infrastructure, run `terraform destory -auto-approve`.


