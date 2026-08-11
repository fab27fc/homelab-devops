output "vpc_id" {
  description = "ID of the Lab 01 VPC"
  value       = aws_vpc.lab.id
}

output "public_subnet_a_id" {
  description = "ID of public subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of public subnet B"
  value       = aws_subnet.public_b.id
}

output "web_a_public_ip" {
  description = "Public IPv4 address of Web Server A"
  value       = aws_instance.web_a.public_ip
}

output "web_b_public_ip" {
  description = "Public IPv4 address of Web Server B"
  value       = aws_instance.web_b.public_ip
}

output "web_a_url" {
  description = "HTTP URL for Web Server A"
  value       = "http://${aws_instance.web_a.public_ip}"
}

output "web_b_url" {
  description = "HTTP URL for Web Server B"
  value       = "http://${aws_instance.web_b.public_ip}"
}