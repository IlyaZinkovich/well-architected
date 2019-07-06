data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"

  tags {
    Name = "private-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_subnet" "public" {
  count                   = "${var.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 4, aws_subnet.private.count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "public-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_traffic" {
  count  = "${aws_subnet.public.count}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "public-routes-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table_association" "public_traffic" {
  count          = "${aws_subnet.public.count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public_traffic.*.id, count.index)}"
}

resource "aws_eip" "ngw_eip" {
  count      = "${aws_subnet.public.count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.igw"]

  tags {
    Name = "ngw-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = "${aws_subnet.public.count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.ngw_eip.*.id, count.index)}"

  tags {
    Name = "ngw-${count.index}"
  }
}

resource "aws_route_table" "egress_only_internet_traffic" {
  count  = "${aws_subnet.private.count}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.ngw.*.id, count.index)}"
  }

  tags {
    Name = "egress-only-routes-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table_association" "egress_only_internet_traffic" {
  count          = "${aws_subnet.private.count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.egress_only_internet_traffic.*.id, count.index)}"
}

# resource "aws_network_acl" "public_traffic" {
#   vpc_id     = "${aws_vpc.main.id}"
#   subnet_ids = ["${aws_subnet.public.*.id}"]

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 102
#     action     = "allow"
#     cidr_block = "${var.home_network_cidr}"
#     from_port  = 22
#     to_port    = 22
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 103
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 102
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   tags {
#     Name = "public-nacl"
#   }
# }

resource "aws_network_acl" "private_traffic" {
  vpc_id     = "${aws_vpc.main.id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "private-nacl"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "controls access to the ALB"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol        = "tcp"
    from_port       = 1024
    to_port         = 65535
    security_groups = ["${aws_security_group.application.id}"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 1024
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "application" {
  name        = "application-security-group"
  description = "controls access to the application behind ALB"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "application-sg"
  }
}

# resource "aws_security_group_rule" "application_ingress" {
#   type                     = "ingress"
#   protocol                 = "tcp"
#   from_port                = 8080
#   to_port                  = 8080
#   security_group_id        = "${aws_security_group.application.id}"
#   source_security_group_id = "${aws_security_group.alb.id}"
# }

# resource "aws_security_group_rule" "application_ingress_ssh" {
#   type              = "ingress"
#   protocol          = "tcp"
#   from_port         = 22
#   to_port           = 22
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "${aws_security_group.application.id}"
# }

# resource "aws_security_group_rule" "application_egress" {
#   type              = "egress"
#   protocol          = "tcp"
#   from_port         = 1024
#   to_port           = 65535
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = "${aws_security_group.application.id}"
# }
