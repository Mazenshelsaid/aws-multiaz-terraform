variable "aws_region" {
  description = "Region this configuration targets. Nothing is deployed from this repo."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "task2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Use at least two availability zones."
  }
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway between all private subnets. Cheaper, but not zone-resilient."
  type        = bool
  default     = false
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_allowed_cidrs" {
  description = "Extra CIDR ranges allowed to reach the database port. Ranges wider than /16 are rejected."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for c in var.db_allowed_cidrs : can(cidrhost(c, 0)) && tonumber(split("/", c)[1]) >= 16
    ])
    error_message = "db_allowed_cidrs must be valid CIDRs no wider than /16. Public ranges such as 0.0.0.0/0 are not allowed."
  }
}

variable "s3_bucket_name" {
  description = "Existing bucket the app role is allowed to read from."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "s3_bucket_name is not a valid S3 bucket name."
  }
}

variable "s3_prefix" {
  description = "Key prefix the app role may read, ending with a slash."
  type        = string
  default     = "app-data/"

  validation {
    condition = (
      length(var.s3_prefix) > 1 &&
      endswith(var.s3_prefix, "/") &&
      !startswith(var.s3_prefix, "/") &&
      !can(regex("\\*", var.s3_prefix))
    )
    error_message = "s3_prefix must be a non-empty key prefix ending in a slash, with no wildcard and no leading slash."
  }
}

variable "object_read_actions" {
  description = "Object-level S3 actions granted on the prefix. Explicit read actions only."
  type        = list(string)
  default     = ["s3:GetObject"]

  validation {
    condition = (
      length(var.object_read_actions) > 0 &&
      alltrue([for a in var.object_read_actions : can(regex("^s3:Get[A-Za-z]+$", a))])
    )
    error_message = "Only explicit s3:Get* actions are allowed. No wildcards and no write actions."
  }
}
