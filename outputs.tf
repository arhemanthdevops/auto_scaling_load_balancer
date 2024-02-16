# outputs.tf

# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

# Output the Security Group ID
output "security_group_id" {
  value = aws_security_group.web_sg.id
}

# Output the Launch Configuration ID
output "launch_configuration_id" {
  value = aws_launch_configuration.web_lc.id
}

# Output the Auto Scaling Group ID
output "auto_scaling_group_id" {
  value = aws_autoscaling_group.web_asg.id
}

# Output the Application Load Balancer DNS Name
output "load_balancer_dns_name" {
  value = aws_lb.web_lb.dns_name
}

