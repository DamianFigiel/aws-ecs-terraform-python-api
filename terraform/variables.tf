##################################################################################
# VARIABLES
##################################################################################

variable "aws_region" {
  type        = string
  description = "AWS region to use for resources."
  default     = "us-east-2"
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnet_count" {
  type        = number
  description = "Number of public subnets to create."
  default     = 3
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Map a public IP address for Subnet instances"
  default     = true
}

variable "instance_type" {
  type        = string
  description = "Type for EC2 Instance"
  default     = "t2.micro"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 Instances to create"
  default     = 2
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
}

variable "github_account" {
  type        = string
  description = "Github account name"
}