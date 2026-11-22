resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app"
  description = "Application instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_vpc" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
  description       = "App traffic from inside the VPC"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS to AWS APIs and package mirrors through the NAT gateway"
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db"
  description = "Database tier, reachable from the app only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Database port from the app security group"
}

resource "aws_vpc_security_group_ingress_rule" "db_extra" {
  for_each = toset(var.db_allowed_cidrs)

  security_group_id = aws_security_group.db.id
  cidr_ipv4         = each.value
  from_port         = var.db_port
  to_port           = var.db_port
  ip_protocol       = "tcp"
  description       = "Extra private range allowed by db_allowed_cidrs"
}
