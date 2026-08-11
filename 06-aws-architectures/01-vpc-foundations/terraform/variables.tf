variable "aws_region" {
  description = "AWS region used for the lab"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
}

variable "availability_zone_a" {
  description = "Availability Zone for public subnet A"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability Zone for public subnet B"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the web servers"
  type        = string
}