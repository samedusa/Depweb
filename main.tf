# create VPC
resource "aws_vpc" "DepWeb-vpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name = "DepWeb-vpc"
  }
}
# create pub subnet 1
resource "aws_subnet" "DepWeb-pubsub01" {
  vpc_id            = aws_vpc.DepWeb-vpc.id
  cidr_block        = var.pubsub01-cidr
  availability_zone = var.az1
  tags = {
    Name = "DepWeb-pubsub01"
  }
}

# create pub subnet 2
resource "aws_subnet" "DepWeb-pubsub02" {
  vpc_id            = aws_vpc.DepWeb-vpc.id
  cidr_block        = var.pubsub02-cidr
  availability_zone = var.az2
  tags = {
    Name = "DepWeb-pubsub02"
  }
}

# create prv subnet 1
resource "aws_subnet" "DepWeb-prvtsub01" {
  vpc_id            = aws_vpc.DepWeb-vpc.id
  cidr_block        = var.prvtsub01-cidr
  availability_zone = var.az1
  tags = {
    Name = "DepWeb-prvtsub01"
  }
}

# create prv subnet 2
resource "aws_subnet" "DepWeb-prvtsub02" {
  vpc_id            = aws_vpc.DepWeb-vpc.id
  cidr_block        = var.prvtsub02-cidr
  availability_zone = var.az2
  tags = {
    Name = "DepWeb-prvtsub02"
  }
}
# create an IGW
resource "aws_internet_gateway" "DepWeb-igw" {
  vpc_id = aws_vpc.DepWeb-vpc.id

  tags = {
    Name = "DepWeb-igw"
  }
}
# create a public route table
resource "aws_route_table" "DepWeb-public-subnet-RT" {
  vpc_id = aws_vpc.DepWeb-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.DepWeb-igw.id
  }
  tags = {
    Name = "DepWeb-public-subnet-RT"
  }
}
# assiociation of route table to public subnet 1
resource "aws_route_table_association" "DepWeb-Public-RT-ass" {
  subnet_id      = aws_subnet.DepWeb-pubsub01.id
  route_table_id = aws_route_table.DepWeb-public-subnet-RT.id
}

# assiociation of route table to public subnet 2
resource "aws_route_table_association" "DepWeb-Public-RT-ass-2" {
  subnet_id      = aws_subnet.DepWeb-pubsub02.id
  route_table_id = aws_route_table.DepWeb-public-subnet-RT.id
}

# Allocate Elastic IP Address (EIP )
# terraform aws allocate elastic ip
resource "aws_eip" "eip-for-nat-gateway" {
  vpc = true

  tags = {
    Name = "EIP_1"
  }
}

# Create Nat Gateway  in Public Subnet 1
# terraform create aws nat gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.eip-for-nat-gateway.id
  subnet_id     = aws_subnet.DepWeb-pubsub01.id

  tags = {
    Name = "nat-gateway"
  }
}

# Create Private Route Table  and Add Route Through Nat Gateway 
# terraform aws create route table
resource "aws_route_table" "DepWeb-private-route-table" {
  vpc_id = aws_vpc.DepWeb-vpc.id

  route {
    cidr_block     = var.all-cidr
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "DepWeb-private-route-table"
  }
}

# Associate Private Subnet 1 with "Private Route Table "
# terraform aws associate subnet with route table
resource "aws_route_table_association" "private-subnet-1-route-table-association" {
  subnet_id      = aws_subnet.DepWeb-prvtsub01.id
  route_table_id = aws_route_table.DepWeb-private-route-table.id
}

# Associate Private Subnet 2 with "Private Route Table "
# terraform aws associate subnet with route table
resource "aws_route_table_association" "private-subnet-2-route-table-association" {
  subnet_id      = aws_subnet.DepWeb-prvtsub02.id
  route_table_id = aws_route_table.DepWeb-private-route-table.id
}

# Create Keypair 
resource "aws_key_pair" "et1pacujp1_rsa" {
  key_name   = "et1pacujp1_rsa"
  public_key = file("~/keypair/et1pacujp1_rsa.pub")
}

# create security group for the application load balancer
# terraform aws create security group
resource "aws_security_group" "alb_security_group" {
  name        = "alb-sg"
  description = "enable http/https access on port 80/443"
  vpc_id      = aws_vpc.DepWeb-vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# create security group for the bastion host aka jump box
# terraform aws create security group
resource "aws_security_group" "ssh_security_group" {
  name        = "ssh-sg"
  description = "enable ssh access on port 22"
  vpc_id      = aws_vpc.DepWeb-vpc.id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all-cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.all-cidr]
  }

  tags = {
    Name = "ssh-sg"
  }
}

# create security group for the web server
# terraform aws create security group
resource "aws_security_group" "webserver_security_group" {
  name        = "webserver-sg"
  description = "enable http/https access on port 80/443 via alb sg and access on port 22 via ssh sg"
  vpc_id      = aws_vpc.DepWeb-vpc.id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description     = "https access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description     = "ssh access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.all-cidr]
  }

  tags = {
    Name = "webserver-sg"
  }
}

# create security group for the database
# terraform aws create security group
resource "aws_security_group" "database_security_group" {
  name        = "database-sg"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_vpc.DepWeb-vpc.id

  ingress {
    description     = "database access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.all-cidr]
  }

  tags = {
    Name = "database-sg"
  }
}

# create database subnet group
# terraform aws db subnet group
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "db-subnet"
  subnet_ids  = [aws_subnet.DepWeb-prvtsub01.id, aws_subnet.DepWeb-prvtsub02.id]
  description = "subnets for database instance"

  tags = {
    Name = "db-subnet"
  }
}

# get the latest db snapshot
# terraform aws data db snapshot
data "aws_db_snapshot" "latest_db_snapshot" {
  db_snapshot_identifier = var.database_snaphot_identifier
  most_recent            = true
  snapshot_type          = "manual"
}

# create database instance restored from db snapshots
# terraform aws db instance
resource "aws_db_instance" "database_instance" {
  instance_class         = var.database_instance_class
  skip_final_snapshot    = true
  availability_zone      = "eu-west-3a"
  identifier             = var.database_instance_identifier
  snapshot_identifier    = data.aws_db_snapshot.latest_db_snapshot.id
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  multi_az               = var.multi_az-deployment
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
}


# create application load balancer
# terraform aws create application load balancer
resource "aws_lb" "application_load_balancer" {
  name               = "Dev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]

  subnet_mapping {
    subnet_id = aws_subnet.DepWeb-pubsub01.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.DepWeb-pubsub02.id
  }

  enable_deletion_protection = false

  tags   = {
    Name = "Dev-alb"
  }
}

# create target group
# terraform aws create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "Dev-Tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.DepWeb-vpc.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200,301,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# create a listener on port 80 with redirect action
# terraform aws create listener
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# create a listener on port 443 with forward action
# terraform aws create listener
resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn  = aws_lb.application_load_balancer.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-2016-08"
  certificate_arn    = var.ssl-certiciate-arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# create an sns topic
# terraform aws create sns topic
resource "aws_sns_topic" "user_updates" {
  name      = "Depweb-sns"
}

# create an sns topic subscription
# terraform aws sns topic subscription
resource "aws_sns_topic_subscription" "notification_topic" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = var.operator_email
}

# create a launch template
# terraform aws launch template
resource "aws_launch_template" "webserver_launch_template" {
  name          = "Depweb-launch-template"
  image_id      = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_keypair_name
  description   = "launch template for ASG"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.webserver_security_group.id]
}

# create auto scaling group
# terraform aws autoscaling group
resource "aws_autoscaling_group" "auto_scaling_group" {
  vpc_zone_identifier = [aws_subnet.DepWeb-prvtsub01.id,aws_subnet.DepWeb-prvtsub02.id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  name                = "dev-asg"
  health_check_type   = "ELB"

  launch_template {
    name    = aws_launch_template.webserver_launch_template.name
    version = "$Latest"
  }

  tag {
    key                 = "name"
    value               = "asg-server"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes      = [target_group_arns]
  }
}

# attach auto scaling group to alb target group
# terraform aws autoscaling attachment
resource "aws_autoscaling_attachment" "asg_alb_target_group_attachment" {
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.id
  lb_target_group_arn    = aws_lb_target_group.alb_target_group.arn
}

# create an auto scaling group notification
# terraform aws autoscaling notification
resource "aws_autoscaling_notification" "webserver_asg_notifications" {
  group_names = [aws_autoscaling_group.auto_scaling_group.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.user_updates.arn
}

# get hosted zone details
# terraform aws data hosted zone
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

# create a record set in route 53
# terraform aws route 53 record
resource "aws_route53_record" "site_domain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}