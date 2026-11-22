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

run "trust_policy_allows_only_ec2" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.app.assume_role_policy).Statement[0].Principal.Service == "ec2.amazonaws.com"
    error_message = "only the EC2 service should be able to assume the role"
  }
}

run "policy_has_two_statements" {
  command = plan

  assert {
    condition     = length(jsondecode(aws_iam_policy.s3_read.policy).Statement) == 2
    error_message = "expected one object statement and one list statement"
  }
}

run "policy_has_no_wildcard_actions" {
  command = plan

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.s3_read.policy).Statement : !can(regex("\\*", join(",", s.Action)))
    ])
    error_message = "no statement may use a wildcard action"
  }
}

run "policy_is_read_only" {
  command = plan

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.s3_read.policy).Statement : alltrue([
        for a in s.Action : can(regex("^s3:(Get|List)[A-Za-z]+$", a))
      ])
    ])
    error_message = "only s3:Get* and s3:List* actions are allowed"
  }
}

run "policy_resources_are_scoped" {
  command = plan

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.s3_read.policy).Statement :
      s.Resource != "*" && startswith(s.Resource, "arn:aws:s3:::example-app-data")
    ])
    error_message = "resources must be the named bucket, never *"
  }

  assert {
    condition     = jsondecode(aws_iam_policy.s3_read.policy).Statement[0].Resource == "arn:aws:s3:::example-app-data/app-data/*"
    error_message = "object access should be limited to the configured prefix"
  }

  assert {
    condition     = jsondecode(aws_iam_policy.s3_read.policy).Statement[1].Condition.StringLike["s3:prefix"][0] == "app-data/*"
    error_message = "ListBucket should be restricted to the prefix"
  }
}

run "instance_profile_uses_the_role" {
  command = plan

  assert {
    condition     = aws_instance.app.iam_instance_profile == "task2-app-profile"
    error_message = "app instance should use the instance profile"
  }
}

run "service_wildcard_action_is_rejected" {
  command = plan

  variables {
    object_read_actions = ["s3:*"]
  }

  expect_failures = [var.object_read_actions]
}

run "bare_wildcard_action_is_rejected" {
  command = plan

  variables {
    object_read_actions = ["*"]
  }

  expect_failures = [var.object_read_actions]
}

run "write_action_is_rejected" {
  command = plan

  variables {
    object_read_actions = ["s3:PutObject"]
  }

  expect_failures = [var.object_read_actions]
}

run "wildcard_prefix_is_rejected" {
  command = plan

  variables {
    s3_prefix = "*"
  }

  expect_failures = [var.s3_prefix]
}
