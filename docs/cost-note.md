# Cost note

Nothing in this repo is deployed. If it were applied in AWS, these are the
resources that could cost money. Figures are us-east-1 list prices when this was
written; check the AWS pricing pages before relying on them.

| Resource | Count | Charge |
|---|---|---|
| NAT gateway | 2 (1 with `single_nat_gateway = true`) | about $0.045 per hour each, roughly $33 per month each, plus $0.045 per GB processed |
| Elastic IP for the NAT gateways | 2 | $0.005 per hour each for the public IPv4 address, about $3.60 per month each |
| EC2 instance (t3.micro) | 1 | about $0.01 per hour, may be covered by the free tier on a new account |
| EBS root volume (8 GB gp3) | 1 | a few cents to under a dollar per month |
| Data transfer out to the internet | - | per GB, after the free allowance |

The NAT gateways dominate: about $66 per month for two before any traffic, or
about $33 with a single gateway.

No charge for the VPC, subnets, route tables, internet gateway, security groups,
IAM role, IAM policy and instance profile.

Ways to lower the bill if this were deployed: set `single_nat_gateway = true`
for non-production, add a free S3 gateway endpoint so S3 reads skip the NAT
gateway, and stop or destroy the environment when it is not needed.
