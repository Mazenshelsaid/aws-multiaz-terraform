# aws-multiaz-terraform

Terraform for a two-AZ VPC with public and private subnets, an internet gateway,
NAT gateways, one application instance in a private subnet, security groups, and
an IAM role limited to read-only access on one S3 prefix.

This is a design exercise. It is never applied and it needs no AWS credentials.
Checks run with `terraform fmt`, `terraform validate` and `terraform test` using
a mocked AWS provider. The mock tests check the configuration, not live AWS
behaviour.

## Layout

    versions.tf, main.tf, variables.tf   provider, locals, inputs
    network.tf                           VPC, subnets, IGW, NAT, route tables
    security.tf                          security groups and rules
    iam.tf                               role, S3 read policy, instance profile
    compute.tf                           application instance
    tests/                               mock provider tests
    scripts/check.sh                     runs fmt, init, validate, test
    docs/                                diagram, least-privilege notes, cost note, test output

## Requirements

Terraform 1.7 or newer (mock providers were added in 1.7). `terraform init`
downloads the AWS provider, so it needs internet access but no AWS account.

## Run the checks

    bash scripts/check.sh

The output is saved to `docs/mock-test-output.txt`.

To run the steps by hand:

    terraform fmt -recursive
    terraform init -backend=false
    terraform validate
    terraform test

## What the tests cover

- network: two zones, subnet CIDRs, NAT gateway and Elastic IP per zone, the
  single NAT option, default routes, private instance with IMDSv2 and encrypted disk
- security: app ingress limited to the VPC range, no SSH, HTTPS-only egress,
  database reachable only from the app security group
- iam: trust policy, read-only actions, no wildcard actions, resources scoped to
  the bucket and prefix
- prohibited cases (these must fail): public database ingress such as
  `0.0.0.0/0`, a database range wider than /16, a wildcard or write S3 action,
  a wildcard prefix

## Inputs

Only `s3_bucket_name` is required. See `terraform.tfvars.example`. Other inputs
(region, zones, CIDR, instance type, ports) have defaults in `variables.tf`.

## More

- `docs/network-diagram.svg`
- `docs/least-privilege.md`
- `docs/cost-note.md`
