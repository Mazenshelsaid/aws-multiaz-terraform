# Least privilege notes

## What the app role can do

The instance role has one customer-managed policy with two statements:

1. `s3:GetObject` on `arn:aws:s3:::<bucket>/<prefix>*`. Objects outside the
   prefix are not readable.
2. `s3:ListBucket` on `arn:aws:s3:::<bucket>`, with a `StringLike` condition on
   `s3:prefix` so listing only works for the same prefix.

There is no write, delete, ACL or policy action, and no `*` in any action or
resource. The role can only be assumed by `ec2.amazonaws.com`, and the instance
gets temporary credentials through its instance profile. No access keys exist
in the code, the variables or the state.

## Why it is shaped this way

- ListBucket applies to the bucket ARN, not to objects, so it is a separate
  statement. The prefix condition is what keeps it from listing the whole bucket.
- `object_read_actions` is validated against `^s3:Get[A-Za-z]+$`, so a wildcard
  or a write action fails at plan time instead of reaching AWS.
- `s3_prefix` must end with a slash and cannot contain a wildcard, so the
  resource ARN cannot silently widen to the whole bucket.

## Network side

- The instance has no public IP and IMDSv2 is required.
- The app security group accepts only the app port from the VPC range, with no
  SSH, and allows outbound traffic on 443 only.
- The database security group accepts its port from the app security group.
  `db_allowed_cidrs` rejects public or very wide ranges.
- The VPC default security group is managed with no rules.

## Not covered

- The bucket policy itself. If the bucket denies by default and the objects use
  a customer-managed KMS key, the role would also need `kms:Decrypt` on that key.
- A way to log in to the instance. There is no SSH. Session Manager would need
  an extra managed policy, which was left out to keep the role S3-read only.
