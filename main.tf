resource "aws_s3_bucket" "tf_state" {
  count = var.manage_state_bucket ? 1 : 0

  # This must be globally unique! Change the numbers/name if you enable this.
  bucket = var.state_bucket_name
  force_destroy = true
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # normally would be true
  }
}

# Empty bucket before deletion to allow destroy to succeed
resource "null_resource" "empty_bucket" {
  count = var.manage_state_bucket ? 1 : 0

  triggers = {
    bucket_name = aws_s3_bucket.tf_state[0].bucket
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${self.triggers.bucket_name} --recursive --region us-east-1 || true"
  }

  depends_on = [aws_s3_bucket.tf_state]
}

# Enable versioning so you can roll back if your state gets corrupted
resource "aws_s3_bucket_versioning" "enabled" {
  count = var.manage_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.tf_state]
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count = var.manage_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [aws_s3_bucket.tf_state]
}

# Block public access to the Terraform state bucket (only if managed here)
resource "aws_s3_bucket_public_access_block" "state_block" {
  count = var.manage_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.default]
}