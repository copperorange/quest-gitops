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