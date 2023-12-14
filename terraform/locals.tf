##################################################################################
# LOCALS
##################################################################################

locals {
  common_tags = {
    terraform = "true"
    project     = var.project
    owner       = var.owner
    environment = var.environment
    cost-center = var.cost-center
  }

  naming_prefix = "${terraform.workspace}-${var.project}"
}