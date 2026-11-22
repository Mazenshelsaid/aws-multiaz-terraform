provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  nat_count = var.single_nat_gateway ? 1 : length(var.availability_zones)

  tags = {
    Project   = var.name_prefix
    ManagedBy = "terraform"
  }

  bucket_arn         = "arn:aws:s3:::${var.s3_bucket_name}"
  object_arn_pattern = "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_prefix}*"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
