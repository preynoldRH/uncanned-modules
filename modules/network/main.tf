resource "aws_vpc" "connected" {
  cidr_block           = var.connected_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name_prefix}-connected-vpc" }
}

resource "aws_internet_gateway" "connected" {
  vpc_id = aws_vpc.connected.id
  tags   = { Name = "${var.name_prefix}-connected-igw" }
}

resource "aws_subnet" "connected_public" {
  vpc_id                  = aws_vpc.connected.id
  cidr_block              = var.connected_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-connected-public" }
}

resource "aws_route_table" "connected_public" {
  vpc_id = aws_vpc.connected.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.connected.id
  }

  tags = { Name = "${var.name_prefix}-connected-public-rt" }
}

resource "aws_route_table_association" "connected_public" {
  subnet_id      = aws_subnet.connected_public.id
  route_table_id = aws_route_table.connected_public.id
}

resource "aws_vpc" "airgap" {
  count                = var.enable_airgap ? 1 : 0
  cidr_block           = var.airgap_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name_prefix}-airgap-vpc" }
}

resource "aws_subnet" "airgap_private" {
  count             = var.enable_airgap ? 1 : 0
  vpc_id            = aws_vpc.airgap[0].id
  cidr_block        = var.airgap_subnet_cidr
  availability_zone = var.availability_zone
  tags              = { Name = "${var.name_prefix}-airgap-private" }
}

resource "aws_route_table" "airgap" {
  count  = var.enable_airgap ? 1 : 0
  vpc_id = aws_vpc.airgap[0].id
  tags   = { Name = "${var.name_prefix}-airgap-rt" }
}

resource "aws_route_table_association" "airgap" {
  count          = var.enable_airgap ? 1 : 0
  subnet_id      = aws_subnet.airgap_private[0].id
  route_table_id = aws_route_table.airgap[0].id
}

resource "aws_vpc_peering_connection" "connected_to_airgap" {
  count       = var.enable_airgap ? 1 : 0
  vpc_id      = aws_vpc.connected.id
  peer_vpc_id = aws_vpc.airgap[0].id
  auto_accept = true
  tags        = { Name = "${var.name_prefix}-vpc-peering" }
}

resource "aws_route" "connected_to_airgap" {
  count                     = var.enable_airgap ? 1 : 0
  route_table_id            = aws_route_table.connected_public.id
  destination_cidr_block    = var.airgap_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.connected_to_airgap[0].id
}

resource "aws_route" "airgap_to_connected" {
  count                     = var.enable_airgap ? 1 : 0
  route_table_id            = aws_route_table.airgap[0].id
  destination_cidr_block    = var.connected_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.connected_to_airgap[0].id
}
