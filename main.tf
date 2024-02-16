# main.tf

# AWS provider configuration
provider "aws" {
  region = var.region  # Specify the AWS region using the variable
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block          = var.vpc_cidr_block
  enable_dns_support  = true
  enable_dns_hostnames = true
}

# Create subnets in the VPC
resource "aws_subnet" "my_subnets" {
  count = length(var.subnet_cidr_blocks)

  vpc_id               = aws_vpc.my_vpc.id
  cidr_block           = var.subnet_cidr_blocks[count.index]
  availability_zone    = var.availability_zones[count.index]
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Add a route to the internet gateway in the main route table
resource "aws_route" "route_to_igw" {
  route_table_id         = aws_vpc.my_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Create a security group for the instances
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Inbound rule: Allow incoming traffic on port 80 (HTTP) from any IP address
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule: Allow incoming traffic on port 22 (SSH) from any IP address for administrative purposes
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule: Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a launch configuration for Auto Scaling Group instances
resource "aws_launch_configuration" "web_lc" {
  name               = "web_lc"
  image_id           = var.ami_id  # Specify the AMI ID for the instances
  instance_type      = "t2.micro"

  lifecycle {
    create_before_destroy = true  # Ensure new launch configuration is created before the old one is destroyed
  }

  security_groups = [aws_security_group.web_sg.id]
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2  # Initial desired number of instances
  max_size             = 5  # Maximum number of instances
  min_size             = 1  # Minimum number of instances
  vpc_zone_identifier = aws_subnet.my_subnets[*].id  # Specify the subnet(s) where instances should be launched
  launch_configuration = aws_launch_configuration.web_lc.id  # Associate the launch configuration with the Auto Scaling Group
}

# Create an Application Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false  # Set to true if the load balancer is internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]  # Associate the security group with the load balancer
  subnets            = aws_subnet.my_subnets[*].id  # Specify the subnet(s) where the load balancer should be created

  enable_deletion_protection = false  # Set to true if you want to enable deletion protection for the load balancer
}

# Define the target group for the Application Load Balancer
resource "aws_lb_target_group" "web_lb_target_group" {
  name        = "web-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"
}

# Create a listener for the load balancer
resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, world!"
      status_code  = 200
    }
  }
}
