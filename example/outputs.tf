output "efs_arn" {
  description = "The ARN of created EFS"
  value       = module.efs.arn
}

output "efs_id" {
  description = "The ID of created EFS"
  value       = module.efs.id
}

output "efs_dns_name" {
  description = "The DNS name of created EFS"
  value       = module.efs.dns_name
}
