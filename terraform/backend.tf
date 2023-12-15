##################################################################################
# BACKEND
##################################################################################

terraform {
  backend "s3" {
    bucket         = "sample-s3-bucket-state" # Replace with your bucket name
    key            = "terraform.tfstate"
    region         = "us-east-2" # Replace with your bucket region
    encrypt        = true
    dynamodb_table = "dynamodb-terraform-remote-state-lock"
  }
}