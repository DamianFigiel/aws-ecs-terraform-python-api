##################################################################################
# LOCALS
##################################################################################

locals {
  common_tags = {
    terraform = "true"
    chain     = var.project
  }

  naming_prefix = "${terraform.workspace}-${var.project}"
}