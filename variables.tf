variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "secrets-encryption"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "secrets-encryption"
    ManagedBy = "Terraform"
  }
}

# KMS Variables
variable "enable_key_rotation" {
  description = "Enable automatic key rotation for KMS keys"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "Duration in days before KMS key deletion"
  type        = number
  default     = 30
}

variable "kms_admin_role_arns" {
  description = "List of IAM role ARNs for KMS administrators"
  type        = list(string)
  default     = []
}

variable "kms_user_role_arns" {
  description = "List of IAM role ARNs for KMS users"
  type        = list(string)
  default     = []
}

# Secrets Manager Variables
variable "enable_secret_rotation" {
  description = "Enable automatic rotation for secrets"
  type        = bool
  default     = true
}

variable "secret_rotation_days" {
  description = "Number of days between automatic secret rotations"
  type        = number
  default     = 30
}

variable "secret_recovery_window" {
  description = "Number of days to recover deleted secrets"
  type        = number
  default     = 7
}

variable "database_credentials" {
  description = "Initial database credentials (will be rotated)"
  type = object({
    username = string
    database = string
  })
  default = {
    username = "admin"
    database = "appdb"
  }
  sensitive = true
}

# RDS Variables
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group (must cover at least 2 AZs for RDS)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must include at least 2 subnets in different Availability Zones to satisfy RDS DB subnet group AZ coverage requirements."
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_backup_retention" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "db_enabled_cloudwatch_logs" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}
