variable "root_segment" {}
variable "public_segment1" {}
variable "public_segment2" {}
variable "private_segment1" {}
variable "private_segment2" {}
variable "public_segment1_az" {}
variable "public_segment2_az" {}
variable "private_segment1_az" {}
variable "private_segment2_az" {}

resource "aws_vpc" "vpc_main" {
    cidr_block = "${var.root_segment}"
}

resource "aws_internet_gateway" "vpc_main-igw" {
    vpc_id = "${aws_vpc.vpc_main.id}"
}

resource "aws_subnet" "vpc_main-public-subnet1" {
    vpc_id = "${aws_vpc.vpc_main.id}"
    cidr_block = "${var.public_segment1}"
    availability_zone = "${var.public_segment1_az}"
}
resource "aws_subnet" "vpc_main-public-subnet2" {
    vpc_id = "${aws_vpc.vpc_main.id}"
    cidr_block = "${var.public_segment2}"
    availability_zone = "${var.public_segment2_az}"
}

resource "aws_subnet" "vpc_main-private-subnet1" {
    vpc_id = "${aws_vpc.vpc_main.id}"
    cidr_block = "${var.private_segment1}"
    availability_zone = "${var.private_segment1_az}"
}

resource "aws_subnet" "vpc_main-private-subnet2" {
    vpc_id = "${aws_vpc.vpc_main.id}"
    cidr_block = "${var.private_segment2}"
    availability_zone = "${var.private_segment2_az}"
}

resource "aws_route_table" "vpc_main-public-rt" {
    vpc_id = "${aws_vpc.vpc_main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.vpc_main-igw.id}"
    }
}

resource "aws_route_table_association" "vpc_main-rta1" {
    subnet_id = "${aws_subnet.vpc_main-public-subnet1.id}"
    route_table_id = "${aws_route_table.vpc_main-public-rt.id}"
}

resource "aws_route_table_association" "vpc_main-rta2" {
    subnet_id = "${aws_subnet.vpc_main-public-subnet2.id}"
    route_table_id = "${aws_route_table.vpc_main-public-rt.id}"
}

resource "aws_security_group" "main_sg" {
    name = "ELB_SG"
    vpc_id = "${aws_vpc.vpc_main.id}"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
