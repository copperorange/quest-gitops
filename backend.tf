# S3 backend configuration via -backend-config flags in terraform init
# This allows fork-friendly setup where each user provides their own bucket name
# See GitHub Actions workflow for how -backend-config is passed during init

terraform {
  backend "s3" {
    # bucket, key, and region are supplied via -backend-config flags in terraform init.
    # DynamoDB state locking is optional — if you want locking, pass
    # -backend-config="dynamodb_table=YOUR_LOCK_TABLE" and create the table first.
    # Example:
    # terraform init -backend-config=bucket=$BACKEND_BUCKET \
    #                -backend-config=key=quest/terraform.tfstate \
    #                -backend-config=region=us-east-1 \
    #                -backend-config=encrypt=true
  }
}

