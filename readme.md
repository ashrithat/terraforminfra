AWS Infrastructure Automation Using Terraform

Overview

This document outlines the implementation of an AWS infrastructure that includes an Application Load Balancer (ALB) spanning three Availability Zones (AZs). It also provisions three EC2 instances, each running Apache and serving unique responses. The ALB is configured with path-based routing rules, and Route 53 private DNS resolves each server by name.

Infrastructure Components

1. VPC & Networking

VPC: A single VPC (10.0.0.0/16) with three public subnets.

Subnets: Three public subnets spread across three AZs (us-east-1a, us-east-1b, us-east-1c).

Internet Gateway: Enables internet access for public subnets.

Route Table & Association: Public subnets are associated with a route table that directs traffic to the internet gateway.

Security Group: Allows inbound HTTP (80) and SSH (22) traffic from any IP.

2. EC2 Instances

Three EC2 instances (t2.micro) deployed across the three public subnets.

Each instance runs Apache (httpd) and displays its server name upon access.

User data is used to install Apache and set up the web pages.

3. Application Load Balancer (ALB)

An internet-facing ALB spanning three AZs.

Three target groups (one per instance).

ALB listener rules forward traffic based on the request path:

/server1 → Server 1

/server2 → Server 2

/interview → Interview Server

Default response for unmatched paths.

4. Route 53 Private DNS

Private hosted zone: dvstech.com

DNS records:

server1.dvstech.com → Server 1

server2.dvstech.com → Server 2

interview.dvstech.com → Interview Server

Implementation Details

1. VPC & Subnets

Terraform resources used:

aws_vpc

aws_subnet

aws_internet_gateway

aws_route_table

aws_route

aws_route_table_association

2. EC2 Instances

Terraform resources used:

aws_instance

aws_security_group

User data script installs and starts Apache (httpd).

3. Application Load Balancer (ALB)

Terraform resources used:

aws_lb

aws_lb_listener

aws_lb_listener_rule

aws_lb_target_group

aws_lb_target_group_attachment

4. Route 53 Private DNS

Terraform resources used:

aws_route53_zone

aws_route53_record

Deployment Steps

Initialize Terraform:

terraform init

Plan infrastructure:

terraform plan

Apply Terraform configuration:

terraform apply -auto-approve

Verify setup:

Check EC2 instances in AWS Console.

Access the ALB with /server1, /server2, and /interview paths.

Use Route 53 private DNS to resolve instance names.

Conclusion

This Terraform script provisions an AWS infrastructure with an ALB, EC2 instances, and a private DNS setup. The ALB directs traffic based on path-based rules, and Route 53 ensures servers are resolvable by their domain names.

