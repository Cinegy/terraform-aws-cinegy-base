
resource "aws_directory_service_directory" "ad" {
  name     = var.domain_name
  password = var.domain_admin_password
  edition  = var.directory_edition
  type     = var.directory_type

  vpc_settings {
    vpc_id = aws_vpc.main.id
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
    ]
  }

  tags = {
    Name      = "${upper(var.environment_name)}-Directory Service"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

resource "aws_ssm_document" "directory_service_default_doc" {
  name          = "directory_service_default_docs-${var.environment_name}"
  document_type = "Command"

  content = <<DOC
    {
            "schemaVersion": "1.0",
            "description": "Join an instance to a domain",
            "runtimeConfig": {
            "aws:domainJoin": {
                "properties": {
                    "directoryId": "${aws_directory_service_directory.ad.id}",
                    "directoryName": "${var.domain_name}",
                    "dnsIpAddresses": [
                        "${sort(aws_directory_service_directory.ad.dns_ip_addresses).0}",
                        "${sort(aws_directory_service_directory.ad.dns_ip_addresses).1}"                    
                    ]
                }
            }
            }
    }
    
DOC


  tags = {
    Env = var.environment_name
    App = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }

  depends_on = [aws_directory_service_directory.ad]
}

