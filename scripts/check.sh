#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
export AWS_EC2_METADATA_DISABLED=true

if ! command -v terraform >/dev/null; then
    echo "terraform is not installed" >&2
    exit 1
fi

ver=$(terraform version | head -n1 | sed 's/^Terraform v//')
major=${ver%%.*}
rest=${ver#*.}
minor=${rest%%.*}
if [ "$major" -lt 1 ] || { [ "$major" -eq 1 ] && [ "$minor" -lt 7 ]; }; then
    echo "terraform 1.7 or newer is required (found $ver)" >&2
    exit 1
fi

out=docs/mock-test-output.txt

{
    echo "run date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "terraform: $ver"
    echo "aws credentials: none used, the provider is mocked in tests"
    echo
    echo '$ terraform fmt -recursive'
    terraform fmt -recursive
    echo
    echo '$ terraform init -backend=false'
    terraform init -backend=false -input=false -no-color
    echo
    echo '$ terraform validate'
    terraform validate -no-color
    echo
    echo '$ terraform test'
    terraform test -no-color
} 2>&1 | tee "$out"
