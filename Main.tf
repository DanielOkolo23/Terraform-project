provider "aws" {
  region     = "eu-west-2"
  access_key = "ACCESS_KEY"
  secret_key = "SECRET_KEY"
}

resource "aws_vpc" "one" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 

  tags = {
    Name = "Whats good "}
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.one.id

  tags = {
    Name = "gateway"
  }
}
resource "aws_route_table" "Assignment-route-table-public" {
  vpc_id = aws_vpc.one.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Assignment-route-table-public"
  }
}

resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "public-subnet1"
  }
}
#Create Public Subnet-2
resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.one.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"
  tags = {
    Name = "public-subnet2"
  }
}
resource "aws_route_table_association" "public-subnet1-association" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.Assignment-route-table-public.id
}
# Associate public subnet 2 with public route table
resource "aws_route_table_association" "public-subnet2-association" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.Assignment-route-table-public.id
}

resource "aws_network_acl" "one" {
  vpc_id = aws_vpc.one.id
   subnet_ids = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.one.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2-security-grp" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for ec2 instances"
  vpc_id      = aws_vpc.one.id
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   
  }
  tags = {
    Name = "EC2-security-grp"
  }
}


resource "aws_instance" "server1" {
  ami             = "ami-0d09654d0a20d3ae2"
  instance_type   = "t2.micro"
  key_name        = "server"
  security_groups = [aws_security_group.ec2-security-grp.id]
  subnet_id       = aws_subnet.public-subnet1.id
  availability_zone = "eu-west-2a"
  tags = {
    Name   = "server1"
    
  }
}
# creating instance 2
 resource "aws_instance" "server2" {
  ami             = "ami-0d09654d0a20d3ae2"
  instance_type   = "t2.micro"
  key_name        = "server"
  security_groups = [aws_security_group.ec2-security-grp.id]
  subnet_id       = aws_subnet.public-subnet2.id
  availability_zone = "eu-west-2b"
  tags = {
    Name   = "server2"
  }
}
# creating instance 3
resource "aws_instance" "server3" {
  ami             = "ami-0d09654d0a20d3ae2"
  instance_type   = "t2.micro"
  key_name        = "server"
  security_groups = [aws_security_group.ec2-security-grp.id]
  subnet_id       = aws_subnet.public-subnet1.id
  availability_zone = "eu-west-2a"
  tags = {
    Name   = "server3"
    
  }
}


resource "aws_lb" "load-balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.server1, aws_instance.server2, aws_instance.server3]

}

resource "aws_lb_target_group" "target-group" {
  name     = "target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.one.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "listener-rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group_attachment" "target-group-attachment1" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.server1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "target-group-attachment2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.server2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "target-group-attachment3" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.server3.id
  port             = 80 
  
  }

 resource "local_file" "Ip_address" {
  filename = "/Vagrant/tterraform/host-inventory"
  content  = <<EOT
${aws_instance.server1.public_ip}
${aws_instance.server2.public_ip}
${aws_instance.server3.public_ip}
  EOT
}
