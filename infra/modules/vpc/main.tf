# /modules/vpc/main.tf

resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.project}-vpc"
    }
}

resource "aws_subnet" "public" {
    count                   = length(var.public_subnet_cidrs)
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.public_subnet_cidrs[count.index]
    map_public_ip_on_launch = true
    availability_zone       = element(var.availability_zones, count.index)
    tags = {
        Name = "${var.project}-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "private" {
    count                   = length(var.private_subnet_cidrs)
    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.private_subnet_cidrs[count.index]
    map_public_ip_on_launch = false
    availability_zone       = element(var.availability_zones, count.index)
    tags = {
        Name = "${var.project}-private-subnet-${count.index}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project}-igw"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project}-public-rt"
    }
}

resource "aws_route" "public_route" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet" {
    count          = length(var.public_subnet_cidrs)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id
    tags = {
        Name = "${var.project}-nat-gateway"
    }
}

resource "aws_eip" "nat" {
    depends_on = [aws_internet_gateway.igw]
    
    tags = {
        Name = "${var.project}-nat-eip"
    }
}


resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project}-private-rt"
    }
}

resource "aws_route" "private_route" {
    route_table_id         = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_subnet" {
    count          = length(var.private_subnet_cidrs)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}
