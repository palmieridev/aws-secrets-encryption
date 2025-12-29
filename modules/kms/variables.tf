variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rotation_enabled" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "deletion_window" {
  description = "Duration in days before key deletion"
  type        = number
  default     = 30
}

variable "admin_role_arns" {
  description = "List of IAM role ARNs for KMS administrators"
  type        = list(string)
  default     = []
}

variable "user_role_arns" {
  description = "List of IAM role ARNs for KMS users"
  type        = list(string)
  default     = []
}
