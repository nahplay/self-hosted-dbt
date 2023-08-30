
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "172.16.0.0/20"
  instance_tenancy = "default"
}

resource "aws_subnet" "ecs_public_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "172.16.0.0/24"

  availability_zone = "eu-west-1a"

  map_public_ip_on_launch = true
}

resource "aws_subnet" "ecs_private_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "172.16.1.0/24"

  availability_zone = "eu-west-1b"
}

resource "aws_internet_gateway" "ecs_internet_gateway" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route" "public_subnet_internet_route" {
  route_table_id         = aws_route_table.public_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs_internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.ecs_public_subnet.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_eip" "nat_gateway_elastic_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ecs_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_elastic_ip.id
  subnet_id     = aws_subnet.ecs_public_subnet.id
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route" "private_subnet_nat_route" {
  route_table_id         = aws_route_table.private_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ecs_nat_gateway.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.ecs_private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}


#First version
#resource "aws_vpc" "ecs_vpc" {
#  cidr_block = "172.16.0.0/20"
#  instance_tenancy = "default"
#}
#
#resource "aws_subnet" "ecs_public_subnet" {
#  depends_on = [
#    aws_vpc.ecs_vpc
#  ]
#
#  vpc_id = aws_vpc.ecs_vpc.id
#
#  cidr_block = "172.16.0.0/24"
#
#  availability_zone = "eu-west-1a"
#
#  map_public_ip_on_launch = true
#}
#
#resource "aws_subnet" "ecs_private_subnet" {
#  vpc_id     = aws_vpc.ecs_vpc.id
#  cidr_block = "172.16.1.0/24"
#
#  depends_on = [aws_vpc.ecs_vpc]
#}
#
#resource "aws_internet_gateway" "ecs_internet_Gateway" {
#  depends_on = [
#    aws_vpc.ecs_vpc,
#    aws_subnet.ecs_private_subnet,
#  ]
#
#  vpc_id = aws_vpc.ecs_vpc.id
#}
#
#resource "aws_route_table" "ecs_route_to_public_subnet" {
#  depends_on = [
#    aws_vpc.ecs_vpc,
#    aws_internet_gateway.ecs_internet_Gateway
#  ]
#
#  vpc_id = aws_vpc.ecs_vpc.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.ecs_internet_Gateway.id
#  }
#}
#
#resource "aws_route_table_association" "RT-IG-Association" {
#
#  depends_on = [
#    aws_vpc.ecs_vpc,
#    aws_subnet.ecs_public_subnet,
#    aws_subnet.ecs_private_subnet,
#    aws_route_table.ecs_route_to_public_subnet
#  ]
#
#  subnet_id      = aws_subnet.ecs_public_subnet.id
#
#  route_table_id = aws_route_table.ecs_route_to_public_subnet.id
#}
#
#resource "aws_eip" "nat_gateway_elastic_ip" {
#  depends_on = [
#    aws_route_table_association.RT-IG-Association
#  ]
#  domain = "vpc"
#}
#
#resource "aws_nat_gateway" "ecs_nat_gateway" {
#  depends_on = [
#    aws_eip.nat_gateway_elastic_ip
#  ]
#
#  allocation_id = aws_eip.nat_gateway_elastic_ip.id
#
#  subnet_id = aws_subnet.ecs_public_subnet.id
#}
#
#resource "aws_route_table" "NAT-Gateway-RT" {
#  depends_on = [
#    aws_nat_gateway.ecs_nat_gateway
#  ]
#
#  vpc_id = aws_vpc.ecs_vpc.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.ecs_nat_gateway.id
#  }
#
#  tags = {
#    Name = "Route Table for NAT Gateway"
#  }
#
#}
#
#resource "aws_route_table_association" "Nat-Gateway-RT-Association" {
#  depends_on = [
#    aws_route_table.NAT-Gateway-RT
#  ]
#
#  subnet_id      = aws_subnet.ecs_private_subnet.id
#
#  route_table_id = aws_route_table.NAT-Gateway-RT.id
#}