resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name = var.app_name
  }
}

# public subnet 1 (ALB)
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "${var.app_name}-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "${var.app_name}-public-1c"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1d"
  cidr_block        = "10.0.3.0/24"

  tags = {
    Name = "${var.app_name}-public-1d"
  }
}

# public subnet 2 (ECS)
# They should be private subnet in production!!
resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.app_name}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.20.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.app_name}-private-1c"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1d"
  cidr_block              = "10.0.30.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.app_name}-private-1d"
  }
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.app_name
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-private"
  }
}

# Route
# all outbound packet will be routed to internet gateway
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# Association
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private.id
}

# Network ACL
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id,
  ]

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 100
  #   action = "allow"
  #   cidr_block = "10.0.1.0/24"
  #   from_port = 80
  #   to_port = 80
  # }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 101
  #   action = "allow"
  #   cidr_block = "10.0.2.0/24"
  #   from_port = 80
  #   to_port = 80
  # }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 102
  #   action = "allow"
  #   cidr_block = "10.0.3.0/24"
  #   from_port = 80
  #   to_port = 80
  # }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 103
  #   action = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port = 443
  #   to_port = 443
  # }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 104
  #   action = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port = 443
  #   to_port = 443
  # }

  # ingress {
  #   protocol = "tcp"
  #   rule_no = 105
  #   action = "allow"
  #   cidr_block = "0.0.0.0/0"
  #   from_port = 443
  #   to_port = 443
  # }

  tags = {
    Name = "${var.app_name}-private"
  }
}