##################################################################################
# NETWORKING
##################################################################################

module "app" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  cidr = var.vpc_cidr_block

  azs            = slice(data.aws_availability_zones.available.names, 0, var.vpc_public_subnet_count)
  public_subnets = [for subnet in range(var.vpc_public_subnet_count) : cidrsubnet(var.vpc_cidr_block, 8, subnet)]

  enable_nat_gateway      = false
  enable_vpn_gateway      = false
  map_public_ip_on_launch = var.map_public_ip_on_launch
  enable_dns_hostnames    = var.enable_dns_hostnames

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-vpc"
  })
}

resource "aws_vpc_dhcp_options" "EC2DHCPOptions" {
  domain_name = "us-east-2.compute.internal"
  tags        = {}
}