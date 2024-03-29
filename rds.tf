
data "aws_subnets" "filtered_subnets" {
  filter {
    name = "vpc-id"
    values = [aws_vpc.main.id]
  }
  tags = {
    Tier = var.rds_subnet_tier
    AZ   = var.rds_subnet_az
  }
}

# Get general account password secret for SA password
data "aws_secretsmanager_secret" "password" {
  arn = var.rds_sysadmin_user_password_secret_arn
}

data "aws_secretsmanager_secret_version" "password" {
  secret_id = data.aws_secretsmanager_secret.password.id
}



################################################################################
# IAM Role for Windows Authentication
################################################################################

data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    sid = "AssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_ad_auth" {
  name                  = "demo-rds-ad-auth"
  description           = "Role used by RDS for Active Directory authentication and authorization"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.rds_assume_role.json

   tags = {
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }

  #This stops any custom tags applied outside of Terraform from getting removed
  lifecycle {
    ignore_changes = [tags]
  }  

}

resource "aws_iam_role_policy_attachment" "rds_directory_services" {
  role       = aws_iam_role.rds_ad_auth.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
}


resource "aws_db_subnet_group" "mssql" {
  description = "The ${var.app_name}-${var.environment_name} RDS ${var.rds_instance_name_prefix} instance ${var.rds_subnet_tier} subnet group."
  subnet_ids  = data.aws_subnets.filtered_subnets.ids

   tags = {
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }

 #This stops any custom tags applied outside of Terraform from getting removed
  lifecycle {
    ignore_changes = [tags]
  }  
}


resource "aws_security_group" "rds_mssql_security_group" {
  name        = "Internal-MSSQL-Traffic-To-RDS-${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}"
  description = "Allows all VPC traffic to RDS MSSQL default port in ${var.app_name}-${var.environment_name}"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }

  #This stops any custom tags applied outside of Terraform from getting removed
  lifecycle {
    ignore_changes = [tags]
  }  
}


data "aws_security_groups" "filtered_domain_controller_group" {
  count   = var.domain_join == true ? 1 : 0

  filter {    
    name   = "group-name"
    values = ["${aws_directory_service_directory.ad[count.index].directory_service_id}_controllers"]
  }

  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
}

resource "aws_db_parameter_group" "clr_enabled" {
  name   = lower("clr-enabled-parameters-${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}")
  family = var.mssql_engine_family

  parameter {
    name  = "clr enabled"
    value = "1"
  }
}

 #Create backup bucket
locals {
  s3_rdsbackup_bucket  = "${lower(var.app_name)}-rdsbackup-${var.environment_name}"
}

resource "aws_s3_bucket" "rdsbackup" {
  bucket = local.s3_rdsbackup_bucket

   tags = {
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }

  #This stops any custom tags applied outside of Terraform from getting removed
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_s3_bucket_acl" "rdsbackup_acl" {
  bucket = aws_s3_bucket.rdsbackup.id
  acl    = "private"
}

resource "aws_iam_role" "iam_role_sql_backup_restore" {
  name        = "IAM_ROLE_SQL_BACKUP_RESTORE-${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}"
  path        = "/"
  description = "RDS SQL Server Native Backup Without Encryption "

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#Create IAM policy to allow access to bucket
 resource "aws_iam_role_policy" "iam_role_sql_backup_s3_access" {
   name   = "IAM_POLICY_SQL_BACKUP_S3_ACCESS-${local.s3_rdsbackup_bucket}"
   role   = aws_iam_role.iam_role_sql_backup_restore.id
   policy = jsonencode(
 {
   "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetBucketLocation"
          ],
          "Resource": [
            "arn:aws:s3:::${local.s3_rdsbackup_bucket}"
            ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
          ],
          "Resource": [
            "arn:aws:s3:::${local.s3_rdsbackup_bucket}/*"
            ]
      }
    ]
 } 
   )
 }
 

resource "aws_db_option_group" "sqlexpress-native-backup-restore" {
  name                     = lower("sqlexpress-native-backup-restore-${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}")
  option_group_description = "DB Option Group for backup and restore on ${var.mssql_engine_family}"
  engine_name              = var.mssql_engine
  major_engine_version     = var.engine_major_version

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.iam_role_sql_backup_restore.arn
    }
  }
}

locals {
  domain_id = element(concat(aws_directory_service_directory.ad.*.id, tolist([""])), 0)
  domain_iam_role_name = aws_iam_role.rds_ad_auth.name
}

resource "aws_db_instance" "mssql" {
  identifier                = lower("${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}")
  allocated_storage         = var.rds_allocated_storage
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = var.mssql_engine
  engine_version            = var.engine_specific_version
  instance_class            = var.rds_instance_class
  multi_az                  = var.rds_multi_az
  username                  = var.mssql_admin_username
  password                  = data.aws_secretsmanager_secret_version.password.secret_string
  publicly_accessible       = var.rds_public_accessible
  vpc_security_group_ids    = [aws_security_group.rds_mssql_security_group.id ]
  db_subnet_group_name      = aws_db_subnet_group.mssql.id
  backup_retention_period   = 3
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = "${var.rds_instance_name_prefix}-${var.app_name}-${var.environment_name}-final-snapshot"
  parameter_group_name      = aws_db_parameter_group.clr_enabled.name
  option_group_name         = aws_db_option_group.sqlexpress-native-backup-restore.name
  domain                    = var.domain_join ? local.domain_id : ""
  domain_iam_role_name      = var.domain_join ? local.domain_iam_role_name : ""

  tags = {
    Env       = var.environment_name
    Terraform = true
  }
}
