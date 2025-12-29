output "db_master_secret_arn" {
  description = "ARN of the database master secret"
  value       = aws_secretsmanager_secret.db_master.arn
}

output "db_master_secret_name" {
  description = "Name of the database master secret"
  value       = aws_secretsmanager_secret.db_master.name
}

output "secret_arns" {
  description = "List of all secret ARNs"
  value = [
    aws_secretsmanager_secret.db_master.arn,
    aws_secretsmanager_secret.app_api_key.arn,
    aws_secretsmanager_secret.app_config.arn
  ]
}

output "app_secret_arns" {
  description = "Map of application secret ARNs"
  value = {
    api_key = aws_secretsmanager_secret.app_api_key.arn
    config  = aws_secretsmanager_secret.app_config.arn
  }
}
