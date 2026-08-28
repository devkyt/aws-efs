# ---------------------------------------------
# Primary EFS File System
# ---------------------------------------------
resource "aws_efs_file_system" "main" {
  creation_token = local.name

  encrypted  = var.encryption.enabled
  kms_key_id = var.encryption.kms_key_id

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy != null ? ["enabled"] : []

    content {
      transition_to_ia                    = var.lifecycle_policy.transition_to_ia
      transition_to_archive               = var.lifecycle_policy.transition_to_archive
      transition_to_primary_storage_class = var.lifecycle_policy.transition_to_primary_storage_class
    }
  }

  tags = merge(local.tags,
    {
      Name = local.name
      Type = "EFS"
    }
  )
}


# ---------------------------------------------
# Mount Targets — One Per Configured Subnet
# ---------------------------------------------
resource "aws_efs_mount_target" "main" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [aws_security_group.main.id]
}


# ---------------------------------------------
# Access Points For Application-Scoped Mounts
# ---------------------------------------------
resource "aws_efs_access_point" "main" {
  for_each = {
    for index, point in var.access_points :
    index => point
  }

  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = each.value.root_path

    creation_info {
      owner_uid   = each.value.user_id
      owner_gid   = each.value.group_id
      permissions = each.value.permissions
    }
  }

  posix_user {
    uid = each.value.user_id
    gid = each.value.group_id
  }

  tags = merge(local.tags,
    {
      Type    = "EFS Access Point"
      Path    = each.value.root_path
      UserId  = each.value.user_id
      GroupId = each.value.group_id
    }
  )
}
