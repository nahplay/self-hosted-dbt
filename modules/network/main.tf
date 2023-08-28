resource "aws_vpc" "ecs_vpc" {
  cidr_block = "172.16.0.0/20"
  instance_tenancy = "default"
}

resource "aws_subnet" "ecs_public_subnet" {
  depends_on = [
    aws_vpc.ecs_vpc
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.ecs_vpc.id

  # IP Range of this subnet
  cidr_block = "172.16.0.0/24"

  # Data Center of this subnet.
  availability_zone = "eu-west-1a"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true
}

resource "aws_subnet" "ecs_private_subnet" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "172.16.1.0/24"

  depends_on = [aws_vpc.ecs_vpc]
}

resource "aws_internet_gateway" "ecs_internet_Gateway" {
  depends_on = [
    aws_vpc.ecs_vpc,
    aws_subnet.ecs_private_subnet,
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "ecs_route_to_public_subnet" {
  depends_on = [
    aws_vpc.ecs_vpc,
    aws_internet_gateway.ecs_internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.ecs_vpc.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_internet_Gateway.id
  }
}

resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.ecs_vpc,
    aws_subnet.ecs_public_subnet,
    aws_subnet.ecs_private_subnet,
    aws_route_table.ecs_route_to_public_subnet
  ]

# Public Subnet ID
  subnet_id      = aws_subnet.ecs_public_subnet.id

#  Route Table ID
  route_table_id = aws_route_table.ecs_route_to_public_subnet.id
}

resource "aws_eip" "nat_gateway_elastic_ip" {
  depends_on = [
    aws_route_table_association.RT-IG-Association
  ]
  domain = "vpc"
}

resource "aws_nat_gateway" "ecs_nat_gateway" {
  depends_on = [
    aws_eip.nat_gateway_elastic_ip
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.nat_gateway_elastic_ip.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.ecs_public_subnet.id
}

resource "aws_route_table" "NAT-Gateway-RT" {
  depends_on = [
    aws_nat_gateway.ecs_nat_gateway
  ]

  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat_gateway.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }

}

resource "aws_route_table_association" "Nat-Gateway-RT-Association" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

#  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.ecs_private_subnet.id

# Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}