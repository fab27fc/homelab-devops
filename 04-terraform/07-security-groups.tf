###############################################
# File:
# 07-security-groups.tf
#
# Description:
# Creates the security groups used by the
# AWS Container Platform.
#
# Lab:
# Lab 04 - AWS Security
###############################################

###############################################
# Application Load Balancer Security Group
###############################################

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Controls inbound and outbound traffic for the Application Load Balancer."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################
# ALB HTTP Ingress Rule
###############################################

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTP traffic from the Internet."
  cidr_ipv4   = "0.0.0.0/0"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

###############################################
# ALB HTTPS Ingress Rule
###############################################

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTPS traffic from the Internet."
  cidr_ipv4   = "0.0.0.0/0"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

###############################################
# ALB Outbound Rule
###############################################

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id

  description = "Allow all outbound traffic."
  cidr_ipv4   = "0.0.0.0/0"

  ip_protocol = "-1"
}

###############################################
# ECS Service Security Group
###############################################

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Controls inbound and outbound traffic for ECS tasks."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################
# ECS Ingress Rule
###############################################

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  description                  = "Allow application traffic from the ALB."
  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

###############################################
# ECS Outbound Rule
###############################################

resource "aws_vpc_security_group_egress_rule" "ecs_all_outbound" {
  security_group_id = aws_security_group.ecs.id

  description = "Allow all outbound traffic."
  cidr_ipv4   = "0.0.0.0/0"

  ip_protocol = "-1"
}