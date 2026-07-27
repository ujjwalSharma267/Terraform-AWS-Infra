# AWS Infrastructure Automation with Terraform

Reusable Terraform module library (VPC, EC2, IAM, S3, CloudWatch) consumed by
separate dev/prod environments, with remote state locking and a GitHub
Actions pipeline that plans on every PR and applies to prod only behind a
manual approval gate.

## Repo layout
```
modules/            vpc, ec2, iam, s3, cloudwatch — generic, reusable
environments/dev/    root module for dev, consumes the modules above
environments/prod/    root module for prod
.github/workflows/   terraform plan (PR) + apply (main, gated) pipeline
docs/                ARCHITECTURE.md and STEPS.md
```

See `docs/ARCHITECTURE.md` for the diagram + rationale and `docs/STEPS.md`
for exact commands.

## Stack
Terraform · AWS (VPC, EC2, IAM, S3, CloudWatch) · GitHub Actions (OIDC) ·
S3 + DynamoDB remote state
