provider "aws" {
  region = "eu-west-1"  # Update with your desired region
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "172.16.0.0/20"
  instance_tenancy = "default"
}

resource "aws_subnet" "ecs_public_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "172.16.0.0/24"

  availability_zone = "eu-west-1a"  # Update with your desired availability zone

  map_public_ip_on_launch = true
}

resource "aws_subnet" "ecs_private_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "172.16.1.0/24"

  availability_zone = "eu-west-1b"  # Update with your desired availability zone
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



#resource "aws_route_table_association" "RT-IG-Association" {
#
#  depends_on = [
#    aws_vpc.ecs_vpc,
#    aws_subnet.ecs_private_subnet,
#    aws_subnet.ecs_private_subnet,
#    aws_route_table.ecs_route_to_private_subnet
#  ]
#
## Public Subnet ID
#  subnet_id      = aws_subnet.ecs_private_subnet.id
#
##  Route Table ID
#  route_table_id = aws_route_table.ecs_route_to_private_subnet.id
#}
#
#resource "aws_nat_gateway" "ecs_nat_gateway" {
#  depends_on = [
#    aws_eip.nat_gateway_elastic_ip
#  ]
#
#  # Allocating the Elastic IP to the NAT Gateway!
#  allocation_id = aws_eip.nat_gateway_elastic_ip.id
#
#  # Associating it in the Public Subnet!
#  subnet_id = aws_subnet.ecs_private_subnet.id
#}
#
#resource "aws_route_table" "ecs_route_to_private_subnet" {
#  depends_on = [
#    aws_vpc.ecs_vpc,
#  ]
#
#  # VPC ID
#  vpc_id = aws_vpc.ecs_vpc.id
#
#  # NAT Rule
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_nat_gateway.ecs_nat_gateway.id
#  }
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
##  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
#  subnet_id      = aws_subnet.ecs_private_subnet.id
#
## Route Table ID
#  route_table_id = aws_route_table.NAT-Gateway-RT.id
#}