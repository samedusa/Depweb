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
    description      = "http access"
    from_port        =  80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
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
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.all-cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [var.all-cidr]
  }

  tags   = {
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
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [var.all-cidr]
  }

  tags   = {
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
    description      = "database access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.webserver_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [var.all-cidr]
  }

  tags   = {
    Name = "database-sg"
  }
}