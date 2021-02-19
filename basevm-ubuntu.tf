# data "template_file" "userdatascript" {
#   template = file(var.userdata_script_path)
# }

data "aws_subnet_ids" "filtered_subnets" {
  vpc_id = aws_vpc.main.id

  tags = {
    Tier = var.aws_subnet_tier
    AZ   = var.aws_subnet_az
  }
}

# resource "aws_ebs_volume" "data_volume" {
#   availability_zone = "${var.aws_region}${lower(var.aws_subnet_az)}"
#   size        = var.data_volume_size
#   count       = var.attach_data_volume == true ? 1 : 0

#   tags = {
#     Name      = "${var.host_name_prefix}-${upper(var.environment_name)}-DATAVOL"
#     Env       = var.environment_name
#     Terraform = true
#   }
# }

# resource "aws_volume_attachment" "data_volume" {
#   device_name = "/dev/sdh"
#   count       = var.attach_data_volume == true ? 1 : 0

#   volume_id   = element(aws_ebs_volume.data_volume.*.id, count.index)
#   instance_id = aws_instance.vm.id
# }

# resource "aws_network_interface_sg_attachment" "remote_access" {
#   security_group_id    = data.terraform_remote_state.vpc.outputs.remote_ssh_security_group
#   network_interface_id = aws_instance.vm.primary_network_interface_id
# }

# resource "aws_network_interface_sg_attachment" "open_access" {
#   count                = var.allow_all_internal_traffic == true ? 1 : 0
#   security_group_id    = data.terraform_remote_state.vpc.outputs.open_internal_access_security_group
#   network_interface_id = aws_instance.vm.primary_network_interface_id
# }

data "aws_ami" "latest_ubuntu_1804" {
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

resource "aws_instance" "vm" {
  ami           = data.aws_ami.latest_ubuntu_1804.id
  key_name      = "terraform-key-${var.app_name}-${var.environment_name}"
  instance_type = var.instance_type
  subnet_id     = var.instance_subnets //element(tolist(data.aws_subnet_ids.filtered_subnets.ids),0)
  //user_data     = data.template_file.userdatascript.rendered
  iam_instance_profile = var.instance_role_name
  root_block_device {
    volume_size = var.root_volume_size
  }

  vpc_security_group_ids = var.security_groups

  tags = {
    Name      = "${var.host_description} - ${upper(var.environment_name)}"
    Hostname  = "${var.host_name_prefix}-${upper(var.environment_name)}"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }

  lifecycle {
    ignore_changes = [user_data,ami]
  }
}

data "aws_route53_zone" "dns_registration" {
  count   = var.create_external_dns_reference == true ? 1 : 0
  name    = var.route53_zone_name
}

resource "aws_route53_record" "vm" {
  count   = var.create_external_dns_reference == true ? 1 : 0
  zone_id = data.aws_route53_zone.dns_registration.*.zone_id[0]
  name    = "${lower(var.host_name_prefix)}-${lower(var.environment_name)}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.vm.public_ip]
}
