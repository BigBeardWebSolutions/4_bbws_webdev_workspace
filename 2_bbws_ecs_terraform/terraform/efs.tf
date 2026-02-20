# EFS Module for POC1 - ECS Fargate Multi-Tenant WordPress

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "${var.environment}-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic" # Elastic throughput per investigation findings

  tags = {
    Name        = "${var.environment}-efs"
    Environment = var.environment
  }
}

# EFS Mount Targets (one per private subnet)
resource "aws_efs_mount_target" "main" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Point for Tenant 1
resource "aws_efs_access_point" "tenant_1" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/tenant-1"
    creation_info {
      owner_gid   = 33 # www-data group
      owner_uid   = 33 # www-data user
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = {
    Name        = "${var.environment}-tenant-1-ap"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}
