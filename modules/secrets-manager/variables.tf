variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting secrets"
  type        = string
}

variable "rotation_enabled" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = true
}

variable "rotation_days" {
  description = "Number of days between rotations"
  type        = number
  default     = 30
}

variable "recovery_window_days" {
  description = "Number of days to recover deleted secrets"
  type        = number
  default     = 7
}

variable "database_credentials" {
  description = "Database credentials configuration"
  type = object({
    username = string
    database = string
  })
  sensitive = true
}
