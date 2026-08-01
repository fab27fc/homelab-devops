###############################################
# File:
# 09-security-outputs.tf
#
# Description:
# Exposes the IDs of security resources created
# for the AWS Container Platform.
#
# Lab:
# Lab 04 - AWS Security
###############################################

###############################################
# Security Group Outputs
###############################################

output "alb_security_group_id" {
  description = "ID of the Application Load Balancer security group."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS service security group."
  value       = aws_security_group.ecs.id
}

###############################################
# Network ACL Outputs
###############################################

output "public_network_acl_id" {
  description = "ID of the public Network ACL."
  value       = aws_network_acl.public.id
}

output "private_network_acl_id" {
  description = "ID of the private Network ACL."
  value       = aws_network_acl.private.id
}