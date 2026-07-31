###############################################
# File:
# 06-network-outputs.tf
#
# Description:
# Exposes networking information generated
# during the Terraform deployment.
#
# Lab:
# Lab 03 - AWS Networking
###############################################

###############################################
# Project Outputs
###############################################

output "aws_region" {
  description = "AWS region configured for this project."
  value       = var.aws_region
}

output "project_name" {
  description = "Project name."
  value       = var.project_name
}

###############################################
# Networking Outputs
###############################################

output "vpc_id" {
  description = "ID of the main VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}