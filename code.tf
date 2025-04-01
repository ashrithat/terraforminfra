provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = { Name = "Main-VPC" }
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "Public-Subnet-AZ1" }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = { Name = "Public-Subnet-AZ2" }
}

resource "aws_subnet" "public_az3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = { Name = "Public-Subnet-AZ3" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "Internet-Gateway" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "Public-Route-Table" }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az3_assoc" {
  subnet_id      = aws_subnet.public_az3.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
  tags = { Name = "Web-Security-Group" }
}

# EC2 Instances
resource "aws_instance" "server1" {
  ami             = "ami-02a53b0d62d37a757"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_az1.id
  security_groups = [aws_security_group.web_sg.id]
  tags            = { Name = "Server1" }

  user_data       = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    echo "Iam server1" > /var/www/html/index.html
    systemctl start httpd 
    mkdir /var/www/html/server1/ 
    echo "Iam server1" > /var/www/html/server1/index.html
  EOF
}

resource "aws_instance" "server2" {
  ami             = "ami-02a53b0d62d37a757"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_az2.id
  security_groups = [aws_security_group.web_sg.id]
  tags            = { Name = "Server2" }

  user_data       = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    echo "Iam server2" > /var/www/html/index.html
    systemctl start httpd 
    mkdir /var/www/html/server2/ 
    echo "Iam server2" > /var/www/html/server2/index.html
  EOF
}

resource "aws_instance" "interview" {
  ami             = "ami-02a53b0d62d37a757"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_az3.id
  security_groups = [aws_security_group.web_sg.id]
  tags            = { Name = "Interview" }

  user_data       = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    echo "Iam interview" > /var/www/html/index.html
    systemctl start httpd
    mkdir /var/www/html/interview/
    echo "Iam interview" > /var/www/html/interview/index.html 
  EOF
}

# Route 53 DNS Records

# Private Hosted Zone for dvstech.com
resource "aws_route53_zone" "private_dns" {
  name = "dvstech.com"
  
  vpc {
    vpc_id = aws_vpc.main.id
  }

}

resource "aws_route53_record" "server1" {
  zone_id = aws_route53_zone.private_dns.zone_id
  name    = "server1.dvstech.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "server2" {
  zone_id = aws_route53_zone.private_dns.zone_id
  name    = "server2.dvstech.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "interview" {
  zone_id = aws_route53_zone.private_dns.zone_id
  name    = "interview.dvstech.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ALB Target Groups & Attachments
resource "aws_lb_target_group" "server1_tg" {
  name     = "server1-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

    health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "server1_attachment" {
  target_group_arn = aws_lb_target_group.server1_tg.arn
  target_id        = aws_instance.server1.id
  port             = 80

  depends_on = [aws_lb.main]  
}

resource "aws_lb_target_group" "server2_tg" {
  name     = "server2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

    health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "server2_attachment" {
  target_group_arn = aws_lb_target_group.server2_tg.arn
  target_id        = aws_instance.server2.id
  port             = 80

  depends_on = [aws_lb.main]  
}

resource "aws_lb_target_group" "interview_tg" {
  name     = "interview-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

    health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "interview_attachment" {
  target_group_arn = aws_lb_target_group.interview_tg.arn
  target_id        = aws_instance.interview.id
  port             = 80

  depends_on = [aws_lb.main]  
}

# ALB
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.web_sg.id]
  subnets            = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id,
    aws_subnet.public_az3.id
  ]
  
  enable_deletion_protection = false
  idle_timeout = 60

  tags = {
    Name = "Main-ALB"
  }
}
# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code    = 200
      content_type   = "text/plain"
      message_body   = "ALB Default Response"
    }
  }
}

# ALB Listener Rule for Server1
resource "aws_lb_listener_rule" "server1_rule" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server1_tg.arn
  }

  condition {
    path_pattern {
      values = ["/server1*"]
    }
  }

  depends_on = [aws_lb_listener.http]
}

# ALB Listener Rule for Server2
resource "aws_lb_listener_rule" "server2_rule" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server2_tg.arn
  }

  condition {
    path_pattern {
      values = ["/server2*"]
    }
  }

  depends_on = [aws_lb_listener.http]
}

# ALB Listener Rule for Interview
resource "aws_lb_listener_rule" "interview_rule" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.interview_tg.arn
  }

  condition {
    path_pattern {
      values = ["/interview*"]
    }
  }

  depends_on = [aws_lb_listener.http]
}
