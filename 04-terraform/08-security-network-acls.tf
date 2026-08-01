###############################################
# File:
# 08-security-network-acls.tf
#
# Description:
# Creates public and private Network ACLs
# for the AWS Container Platform.
#
# Lab:
# Lab 04 - AWS Security
###############################################

###############################################
# Public Network ACL
###############################################

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${local.name_prefix}-public-nacl"
  }
}

###############################################
# Public NACL Inbound HTTP
###############################################

resource "aws_network_acl_rule" "public_http_inbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

###############################################
# Public NACL Inbound HTTPS
###############################################

resource "aws_network_acl_rule" "public_https_inbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

###############################################
# Public NACL Inbound Ephemeral Ports
###############################################

resource "aws_network_acl_rule" "public_ephemeral_inbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

###############################################
# Public NACL Outbound Traffic
###############################################

resource "aws_network_acl_rule" "public_all_outbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

###############################################
# Private Network ACL
###############################################

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-private-nacl"
  }
}

###############################################
# Private NACL Inbound from VPC
###############################################

resource "aws_network_acl_rule" "private_vpc_inbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

###############################################
# Private NACL Inbound Ephemeral Ports
###############################################

resource "aws_network_acl_rule" "private_ephemeral_inbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

###############################################
# Private NACL Outbound Traffic
###############################################

resource "aws_network_acl_rule" "private_all_outbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}