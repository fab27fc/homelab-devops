###############################################
# File:
# 03-network-internet-gateway.tf
#
# Description:
# Creates and attaches an Internet Gateway
# to the main VPC.
#
# Lab:
# Lab 03 - AWS Networking
###############################################

###############################################
# Internet Gateway
###############################################


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}