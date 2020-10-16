output "main_vpc" {
  value = aws_vpc.main.id
}

output "main_vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnets" {
  value = {
    "a" = aws_subnet.public_a.id
    "b" = aws_subnet.public_b.id
  }
}

output "private_subnets" {
  value = {
    "a" = aws_subnet.private_a.id
    "b" = aws_subnet.private_b.id
  }
}

output "remote_access_security_group" {
  value = aws_security_group.remote_access.id
}

output "remote_ssh_security_group" {
  value = aws_security_group.remote_access_ssh.id
}

output "remote_access_udp_6000_6100" {
  value = aws_security_group.remote_access_udp_6000_6100.id
}

output "remote_access_playout_engine_rest_5521_5600" {
  value = aws_security_group.remote_access_tcp_5521_5600.id
}

output "remote_access_playout_control_rest_7501" {
  value = aws_security_group.remote_access_tcp_7501.id
}

output "remote_access_http" {
  value = aws_security_group.remote_access_tcp_80.id
}

output "remote_access_https" {
  value = aws_security_group.remote_access_tcp_443.id
}

output "open_internal_access_security_group" {
  value = aws_security_group.open_internal.id
}
