# Quest GitOps (short)

What it is
- Terraform code that deploys AWS infrastructure needed by the Quest app (VPC, ALB, ECS, ECR).

Purpose
- Keep infrastructure as code and run Terraform from GitHub Actions so CI can plan/apply/destroy.

How to trigger
- Push to `main`: workflow runs a `terraform plan` (checks for changes).
- Actions → **Terraform Plan & Apply** → Run workflow (choose `plan`, `apply`, or `destroy`).

Basic things to know
- Set these GitHub secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TERRAFORM_STATE_BUCKET`.
- The workflow passes the bucket name to `terraform init` via `-backend-config`.
 - Create S3 bucket once (see `backend.hcl.example`). If you want state locking in
       production, create a DynamoDB lock table and add `dynamodb_table` to your backend config.
- For local runs use `terraform init -backend-config=backend.hcl` and pass `-var='manage_state_bucket=false'`.

That's it — the GitHub Actions runner runs `terraform apply` against your AWS account using the repo's code and the provided secrets.

## Validation Steps

For a complete walkthrough of validating the setup, see **TERRAFORM_VALIDATION.md**.

## Workflow Diagram

```
GitHub Actions Runner
        ↓
  AWS Credentials (from secrets)
        ↓
  terraform init -backend-config
        ↓
  terraform validate
        ↓
  terraform plan
        ↓
  [Manual Review]
        ↓
  terraform apply / destroy
        ↓
  AWS Resources (VPC, ALB, ECS, ECR)
        ↓
      Terraform State → S3 (optional: DynamoDB locking)
```

## Cost Estimation

Rough AWS costs (us-east-1, on-demand):
- **ALB**: ~$16/month + data processing (~$0.25/GB)
- **ECS Fargate**: ~$15/month (256MB, 0.25 CPU)
- **ECR**: $0.10/GB/month for storage
- **S3/DynamoDB**: Minimal (<$1/month for state storage)

**Total**: ~$30-50/month for production-like setup

## Contributing

Before committing changes to `main`, ensure:

```bash
# Validate Terraform syntax
terraform validate

# Check formatting
terraform fmt -check

# Plan changes and review
terraform plan -var='manage_state_bucket=false'

# Commit only .tf files and documentation
git add *.tf *.md README.md
```

## References

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS S3 Backend](https://www.terraform.io/language/settings/backends/s3)
