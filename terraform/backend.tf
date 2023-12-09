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

##################################################################################
#TODO: tags
#TODO: variables
#TODO: change configuration of image to have more tags then just latest!!!  https://stackoverflow.com/questions/31963525/is-it-possible-for-image-to-have-multiple-tags

#TODO: Try now, should be good after updating userdata
