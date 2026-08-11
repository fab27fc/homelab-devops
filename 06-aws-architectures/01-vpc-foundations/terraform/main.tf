# ============================================================
# VPC
# Creates the main isolated network for this lab.
# ============================================================

resource "aws_vpc" "lab" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = false

  tags = {
    Name = "saa-lab01-vpc"
  }
}


# ============================================================
# PUBLIC SUBNET A
# Located in Availability Zone A.
# ============================================================

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = var.availability_zone_a

  # EC2 instances launched here can automatically
  # receive a public IPv4 address.
  map_public_ip_on_launch = true

  tags = {
    Name = "saa-lab01-public-subnet-a"
  }
}


# ============================================================
# PUBLIC SUBNET B
# Located in Availability Zone B.
# ============================================================

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = var.availability_zone_b

  map_public_ip_on_launch = true

  tags = {
    Name = "saa-lab01-public-subnet-b"
  }
}


# ============================================================
# INTERNET GATEWAY
# Provides connectivity between the VPC and the Internet.
# ============================================================

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "saa-lab01-igw"
  }
}


# ============================================================
# PUBLIC ROUTE TABLE
# Sends Internet-bound traffic through the Internet Gateway.
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = {
    Name = "saa-lab01-public-rt"
  }
}


# ============================================================
# ROUTE TABLE ASSOCIATIONS
# Associates both public subnets with the public route table.
# ============================================================

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# WEB SECURITY GROUP
# Allows HTTP traffic from the Internet.
# ============================================================

resource "aws_security_group" "web" {
  name        = "saa-lab01-web-sg"
  description = "Allow HTTP traffic to Lab 01 web servers"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "saa-lab01-web-sg"
  }
}


# Allow inbound HTTP traffic on TCP port 80.
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP from the Internet"
}


# Allow the EC2 instances to initiate outbound connections.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow all outbound traffic"
}


# ============================================================
# AMAZON LINUX 2023 AMI
# Finds the latest Amazon Linux 2023 x86_64 AMI.
# ============================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ============================================================
# WEB SERVER A
# EC2 instance deployed in public subnet A.
# ============================================================

resource "aws_instance" "web_a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat <<'HTML' > /var/www/html/index.html
    <h1>AWS SAA Lab 01</h1>
    <h2>Web Server A - us-east-1a</h2>
    <p>Deployed with Terraform.</p>
    HTML
  EOF

  tags = {
    Name = "saa-lab01-web-a"
  }
}


# ============================================================
# WEB SERVER B
# EC2 instance deployed in public subnet B.
# ============================================================

resource "aws_instance" "web_b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.public_b.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat <<'HTML' > /var/www/html/index.html
    <h1>AWS SAA Lab 01</h1>
    <h2>Web Server B - us-east-1b</h2>
    <p>Deployed with Terraform.</p>
    HTML
  EOF

  tags = {
    Name = "saa-lab01-web-b"
  }
}

