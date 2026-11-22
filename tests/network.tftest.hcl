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

run "vpc_defaults" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should be 10.0.0.0/16"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled"
  }
}

run "two_zones_public_and_private" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "expected two public and two private subnets"
  }

  assert {
    condition     = length(distinct([for s in aws_subnet.public : s.availability_zone])) == 2
    error_message = "public subnets must be in two different zones"
  }

  assert {
    condition     = length(distinct([for s in aws_subnet.private : s.availability_zone])) == 2
    error_message = "private subnets must be in two different zones"
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.0.10.0/24" && aws_subnet.private[1].cidr_block == "10.0.11.0/24"
    error_message = "private subnets should be 10.0.10.0/24 and 10.0.11.0/24"
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "public subnets should not hand out public IPs automatically"
  }
}

run "nat_gateway_per_zone_by_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.main) == 2 && length(aws_eip.nat) == 2
    error_message = "expected one NAT gateway and one Elastic IP per zone"
  }

  assert {
    condition     = length(aws_route_table.private) == 2 && length(aws_route.private_nat) == 2
    error_message = "each private subnet should have its own route table with a NAT route"
  }
}

run "single_nat_gateway_option" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1 && length(aws_eip.nat) == 1
    error_message = "expected a single NAT gateway when single_nat_gateway is true"
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "both private route tables should still point at the NAT gateway"
  }
}

run "default_routes" {
  command = plan

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "public route table needs a default route to the internet gateway"
  }

  assert {
    condition     = alltrue([for r in aws_route.private_nat : r.destination_cidr_block == "0.0.0.0/0"])
    error_message = "private route tables need a default route to a NAT gateway"
  }
}

run "app_instance_settings" {
  command = plan

  assert {
    condition     = aws_instance.app.associate_public_ip_address == false
    error_message = "app instance must not get a public IP"
  }

  assert {
    condition     = aws_instance.app.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required"
  }

  assert {
    condition     = aws_instance.app.root_block_device[0].encrypted == true
    error_message = "root volume must be encrypted"
  }
}
