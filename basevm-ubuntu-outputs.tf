output "instance_hostname" {
  value = "${var.host_name_prefix}-${upper(var.environment_name)}"
}

output "instance" {
  value = aws_instance.vm
}

output "dns_access" {
  value = aws_route53_record.vm.*.name
}

#output "temp" {
#  value = data.template_file.userdatascript.rendered
#}