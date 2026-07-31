###############################################
# File:
# 01-network-vpc.tf
#
# Description:
# Creates the main AWS VPC used by the
# container platform.
#
# Lab:
# Lab 03 - AWS Networking
###############################################

###############################################
# Main VPC
###############################################


resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}