# End-to-End Setup Steps

## 1. One-time bootstrap (state backend)
```bash
aws s3api create-bucket --bucket <your-unique-tf-state-bucket> --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```
Update the bucket name in both `environments/dev/main.tf` and `environments/prod/main.tf`.

## 2. Deploy dev
```bash
cd environments/dev
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## 3. Verify
```bash
terraform output
aws ec2 describe-instances --filters "Name=tag:Name,Values=dev-web"
```

## 4. Set up GitHub Actions OIDC role
- Create OIDC provider for `token.actions.githubusercontent.com` (skip if it already exists from another project).
- Create IAM role `github-actions-terraform` with a trust policy scoped to this repo, and permissions to manage VPC/EC2/IAM/S3/CloudWatch resources.
- Add a GitHub Environment called `production` with required reviewers, so `apply` to prod always needs a human approval click.

## 5. Promote a change through the pipeline
```bash
git checkout -b add-cw-alarm
# edit modules/cloudwatch or environments/dev
git push origin add-cw-alarm
# open PR -> Actions posts terraform plan as a check
# merge to main -> apply job waits on "production" environment approval
```

## 6. Repeat for prod
```bash
cd environments/prod
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## 7. Tear down (avoid ongoing AWS charges)
```bash
cd environments/dev && terraform destroy
cd ../prod && terraform destroy
```
