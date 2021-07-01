locals {
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
  description = "The ${var.environment_name} RDS ${var.rds_instance_name_prefix} instance private subnet group."
  subnet_ids  = ["${data.aws_subnet_ids.filtered_subnets.ids}"]

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
  name        = "Internal-MSSQL-Traffic-To-RDS-${var.rds_instance_name_prefix}-${var.environment_name}"
  description = "Allows all VPC traffic to RDS MSSQL default port in ${var.environment_name}"
  vpc_id      = "${data.terraform_remote_state.vpc.main_vpc}"

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.main_vpc_cidr}"]
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
    values = ["${data.terraform_remote_state.directoryservice[count.index].outputs.directory_service_id}_controllers"]
  }

  filter {
    name   = "vpc-id"
    values = ["${data.terraform_remote_state.vpc.outputs.main_vpc}"]
  }
}



################################################################################
# RDS Creation
################################################################################

resource "aws_db_instance" "default_mssql" {
  depends_on                = ["aws_db_subnet_group.default_rds_mssql"]
  identifier                = "${var.environment}-mssql"
  allocated_storage         = "${var.rds_allocated_storage}"
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = "sqlserver-se"
  engine_version            = "12.00.4422.0.v1"
  instance_class            = "${var.rds_instance_class}"
  multi_az                  = "${var.rds_multi_az}"
  username                  = "${var.mssql_admin_username}"
  password                  = "${var.mssql_admin_password}"
  vpc_security_group_ids    = ["${aws_security_group.rds_mssql_security_group.id}", "${aws_security_group.rds_mssql_security_group_vpn.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.default_rds_mssql.id}"
  backup_retention_period   = 3
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${var.environment}-mssql-final-snapshot"

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
