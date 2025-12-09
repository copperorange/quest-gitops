variable "secret_word" {
  description = "Inject an environment variable (SECRET_WORD) in the Docker container using the value on the index page."
  type        = string
  default     = "Placeholder" # Update once known
}

variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 0 # Start with 0
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "quest-terraform-state-cbell-0001"
}

variable "manage_state_bucket" {
  description = "When true, Terraform will create and manage the S3 state bucket and related resources. Set to false when using an existing bucket/backed by CI."
  type        = bool
  default     = true
}