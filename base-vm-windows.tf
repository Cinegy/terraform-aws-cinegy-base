
# Get any secrets needed for VM instancing
//data "aws_secretsmanager_secret" "privatekey" {
//  arn = var.aws_secrets_privatekey_arn
//}

//data "aws_secretsmanager_secret_version" "privatekey" {
//  secret_id = data.aws_secretsmanager_secret.privatekey.id
//}

data "aws_subnet_ids" "filtered_subnets" {
  vpc_id = aws_vpc.main.id

  tags = {
    Tier = var.aws_subnet_tier
    AZ   = var.aws_subnet_az
  }
}

resource "aws_ssm_association" "domain_ssm" {
  name        = aws_ssm_document.directory_service_default_doc.name
  instance_id = aws_instance.vm.id
}

data "aws_ami" "latest_windows" {
  most_recent = true
  owners      = ["801119661308"] #amazon

  filter {
    name   = "name"
    values = [var.amazon_owned_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = "${var.aws_region}${lower(var.aws_subnet_az)}"
  size              = var.data_volume_size
  count             = var.attach_data_volume == true ? 1 : 0

  tags = {
    Name      = "${var.host_name_prefix}-${upper(var.environment_name)}-DATAVOL"
    Env       = var.environment_name
    App = "${var.app_name}"
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

resource "aws_volume_attachment" "data_volume" {
  device_name = "/dev/sdh"
  count       = var.attach_data_volume == true ? 1 : 0

  volume_id   = element(aws_ebs_volume.data_volume.*.id, count.index)
  instance_id = aws_instance.vm.id
}

resource "aws_network_interface_sg_attachment" "remote_access" {
  count                = var.allow_open_rdp_access == true ? 1 : 0
  security_group_id    = aws_security_group.remote_access.id
  network_interface_id = aws_instance.vm.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "open_access" {
  count                = var.allow_all_internal_traffic == true ? 1 : 0
  security_group_id    = aws_security_group.open_internal.id
  network_interface_id = aws_instance.vm.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "open_media_port_access" {
  count                = var.allow_media_udp_ports_externally == true ? 1 : 0
  security_group_id    = aws_security_group.remote_access_udp_6000_6100.id
  network_interface_id = aws_instance.vm.primary_network_interface_id
}

resource "aws_instance" "vm" {
  ami                  = data.aws_ami.latest_windows.id
  key_name             = "terraform-key-${var.app_name}-${var.environment_name}"
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.instance_profile_default_ec2_instance.name
  subnet_id            = element(tolist(data.aws_subnet_ids.filtered_subnets.ids),0)
  get_password_data    = true
  tenancy              = var.tenancy
  //user_data = format(
  //  "<powershell>%s</powershell>",
  //  data.template_file.userdatascript.rendered,
  //)
  ebs_optimized = true

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name      = "${var.host_description} - ${upper(var.environment_name)}"
    Hostname  = "${var.host_name_prefix}-${upper(var.environment_name)}"
    Env       = var.environment_name
    App       = "${var.app_name}"
    CUSTOMER  = var.customer_tag
    Terraform = true
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

/*
resource "aws_route53_record" "vm" {
  count   = var.create_external_dns_reference == true ? 1 : 0
  zone_id = var.shared_route53_zone_id
  name    = "${lower(var.host_name_prefix)}-${lower(var.environment_name)}.${var.shared_route53_zone_suffix}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.vm.public_ip]
}
*/
