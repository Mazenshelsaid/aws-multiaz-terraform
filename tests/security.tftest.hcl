mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

variables {
  s3_bucket_name = "example-app-data"
}

run "app_ingress_is_limited_to_the_vpc" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_vpc.cidr_ipv4 == "10.0.0.0/16"
    error_message = "app ingress should only allow the VPC range"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_vpc.from_port == 8080
    error_message = "app ingress should be the app port only"
  }
}

run "no_ssh_and_no_open_ingress_on_app" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_vpc.from_port != 22
    error_message = "SSH must not be opened"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_vpc.cidr_ipv4 != "0.0.0.0/0"
    error_message = "app ingress must not be open to the internet"
  }
}

run "app_egress_is_https_only" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_egress_rule.app_https_out.from_port == 443 && aws_vpc_security_group_egress_rule.app_https_out.to_port == 443
    error_message = "app egress should be limited to port 443"
  }
}

run "db_only_accepts_the_app_security_group" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.db_from_app.from_port == 5432
    error_message = "db ingress should be the database port"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.db_extra) == 0
    error_message = "no extra db ingress rules should exist by default"
  }
}

run "private_db_range_is_accepted" {
  command = plan

  variables {
    db_allowed_cidrs = ["10.0.10.0/24"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.db_extra) == 1
    error_message = "a private range should produce one extra rule"
  }
}

run "public_ipv4_db_ingress_is_rejected" {
  command = plan

  variables {
    db_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.db_allowed_cidrs]
}

run "wide_db_range_is_rejected" {
  command = plan

  variables {
    db_allowed_cidrs = ["10.0.0.0/8"]
  }

  expect_failures = [var.db_allowed_cidrs]
}
