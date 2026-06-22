resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/20" # 4096 IPs, Range: 10.0.0.0-10.0.15.255

  tags = {
    Name = "${var.project}-vpc"
  }
}

### Private 

resource "aws_subnet" "cluster_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/28" # 16 IPs, Range: 10.0.0.0-10.0.0.15
  availability_zone = "us-east-1a"

  tags = {
    Name                                           = "${var.project}-cluster-a"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}

resource "aws_subnet" "cluster_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/28" # 16 IPs, Range: 10.0.1.0-10.0.1.15
  availability_zone = "us-east-1b"

  tags = {
    Name                                           = "${var.project}-cluster-b"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}

resource "aws_subnet" "ng_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24" # 256 IPs, Range: 10.0.2.0-10.0.2.255
  availability_zone = "us-east-1a"

  tags = {
    Name                                           = "${var.project}-ng-a"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}

resource "aws_subnet" "ng_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24" # 256 IPs, Range: 10.0.3.0-10.0.3.255
  availability_zone = "us-east-1b"

  tags = {
    Name                                           = "${var.project}-ng-b"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "ng_a" {
  subnet_id      = aws_subnet.ng_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "ng_b" {
  subnet_id      = aws_subnet.ng_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_gateway.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    "Name" = "${var.project}-nat-gateway"
  }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"
}


### Public

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/28" # 16 IPs, Range: 10.0.4.0-10.0.4.15
  availability_zone = "us-east-1a"

  tags = {
    Name                                           = "${var.project}-public"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.project}-cluster" = "owned"
  }

}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}