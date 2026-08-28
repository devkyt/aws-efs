# ---------------------------------------------
# Automatic Backup Policy For The File System
# ---------------------------------------------
resource "aws_efs_backup_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = var.backup_enabled ? "ENABLED" : "DISABLED"
  }
}


# ---------------------------------------------
# Cross-Region Replication — One Per Replica
# ---------------------------------------------
resource "aws_efs_replication_configuration" "main" {
  for_each = {
    for index, replica in var.replicas :
    index => replica
  }

  source_file_system_id = aws_efs_file_system.main.id

  destination {
    region                 = each.value.region
    availability_zone_name = each.value.availability_zone_name
    file_system_id         = each.value.file_system_id
    kms_key_id             = each.value.kms_key_id
  }
}
