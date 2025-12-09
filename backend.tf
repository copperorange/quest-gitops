# S3 backend configuration via -backend-config flags in terraform init
# This allows fork-friendly setup where each user provides their own bucket name
# See GitHub Actions workflow for how -backend-config is passed during init

terraform {
  backend "s3" {
    # bucket, key, region, encrypt, and dynamodb_table are supplied via:
    # terraform init -backend-config=bucket=$BACKEND_BUCKET \
    #                -backend-config=key=quest/terraform.tfstate \
    #                -backend-config=region=us-east-1 \
    #                -backend-config=dynamodb_table=$LOCK_TABLE \
    #                -backend-config=encrypt=true
  }
}

