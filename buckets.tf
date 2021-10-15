resource "aws_s3_bucket" "infra" {
  bucket = "${lower(var.app_name)}-infra-${var.environment_name}"
  acl    = "private"


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