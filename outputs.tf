output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS encryption key"
  value       = module.kms.key_arn
}

output "kms_alias_name" {
  description = "Alias name of the KMS key"
  value       = module.kms.alias_name
}

output "db_master_secret_arn" {
  description = "ARN of the database master credentials secret"
  value       = module.secrets_manager.db_master_secret_arn
  sensitive   = true
}

output "db_master_secret_name" {
  description = "Name of the database master credentials secret"
  value       = module.secrets_manager.db_master_secret_name
}

output "app_secrets_arns" {
  description = "ARNs of application secrets"
  value       = module.secrets_manager.app_secret_arns
  sensitive   = true
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "rds_security_group_id" {
  description = "Security group ID attached to RDS"
  value       = module.rds.security_group_id
}

output "app_role_arn" {
  description = "ARN of the IAM role for application access"
  value       = module.iam.app_role_arn
}

output "app_role_name" {
  description = "Name of the IAM role for application access"
  value       = module.iam.app_role_name
}

output "readonly_role_arn" {
  description = "ARN of the read-only IAM role"
  value       = module.iam.readonly_role_arn
}
