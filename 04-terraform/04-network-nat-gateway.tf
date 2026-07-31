###############################################
# File:
# 04-network-nat-gateway.tf
#
# Description:
# Creates an Elastic IP and a single NAT
# Gateway for outbound private subnet traffic.
#
# Lab:
# Lab 03 - AWS Networking
###############################################


###############################################
# Elastic IP for NAT Gateway
###############################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}


###############################################
# NAT Gateway
###############################################

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.name_prefix}-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}