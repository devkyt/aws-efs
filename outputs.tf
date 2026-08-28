output "arn" {
  description = "ARN of the created EFS"
  value       = aws_efs_file_system.main.arn
}


output "id" {
  description = "ID of the created EFS"
  value       = aws_efs_file_system.main.id
}


output "name" {
  description = "Name of the created EFS"
  value       = aws_efs_file_system.main.creation_token
}


output "dns_name" {
  description = "DNS name of the created EFS"
  value       = aws_efs_file_system.main.dns_name
}


output "access_point_arns" {
  description = "ARNs of the created access points for EFS"
  value       = values(aws_efs_access_point.main)[*].arn
}


output "security_group_id" {
  description = "ID of the security group created for EFS"
  value       = aws_security_group.main.id
}
