
provider "aws" {
  region  = var.aws_region
  version = "~> 2.33"
}

provider "tls" {
  version = "~> 2.0"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.app_name} ${upper(var.environment_name)} VPC"
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }
  
  lifecycle {
    ignore_changes = [ tags ] //don't mess with names or CUSTOMER values once created
  }

}

# Create an elastic IP for the NAT gateway
resource "aws_eip" "nat_1a" {
  vpc = true

  tags = {
    Name      = "NAT GW 1a EIP"
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Env       = var.environment_name
    Terraform = true
  }
  
  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Create an elastic IP for the NAT gateway
resource "aws_eip" "nat_1b" {
  vpc = true
  count = var.secondary_az_enabled ? 1 : 0
  
  tags = {
    Name      = "NAT GW 1b EIP"
    Env       = var.environment_name
    CUSTOMER  = var.customer_tag
    App       = var.app_name
    Terraform = true
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Env       = var.environment_name
    Name      = "${var.app_name}-${var.environment_name}-IGW"
    CUSTOMER  = var.customer_tag
    App       = var.app_name
    Terraform = true
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Create a NAT gateway for private subnets to use
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name      = "NAT GW 1a"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
  
  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Create a 2nd NAT gateway for private subnets to use
resource "aws_nat_gateway" "nat_1b" {
  allocation_id = aws_eip.nat_1b[0].id
  subnet_id     = aws_subnet.public_b.id
  count = var.secondary_az_enabled ? 1 : 0

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name      = "NAT GW 1b"
    Env       = var.environment_name
    CUSTOMER  = var.customer_tag
    App       = var.app_name
    Terraform = true
  }
  
  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# allow internet access to private subnets in AZ-A through nat #1a
resource "aws_route_table" "nat_gw_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "Private 1a subnets via NAT GW 1a"
    Env       = var.environment_name
    CUSTOMER  = var.customer_tag
    App       = var.app_name
    Terraform = true
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# add a default route for nat_gw1a
resource "aws_route" "default_gw_nat_gw1a" {
  route_table_id         = aws_route_table.nat_gw_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route_table_association" "private_a_subnet_to_nat_gw_1a" {
  route_table_id = aws_route_table.nat_gw_1a.id
  subnet_id      = aws_subnet.private_a.id
}

# allow internet access to private subnets in AZ-B through nat #1b
resource "aws_route_table" "nat_gw_1b" {
  vpc_id = aws_vpc.main.id
  count = var.secondary_az_enabled ? 1 : 0

  tags = {
    Name      = "Private 1b subnets via NAT GW 1b"
    Env       = var.environment_name
    CUSTOMER  = var.customer_tag
    App       = var.app_name
    Terraform = true
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# add a default route for nat_gw1b
resource "aws_route" "default_gw_nat_gw1b" {
  count = var.secondary_az_enabled ? 1 : 0
  route_table_id         = aws_route_table.nat_gw_1b[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1b[count.index].id
}

resource "aws_route_table_association" "private_b_subnet_to_nat_gw_1b" {
  count = var.secondary_az_enabled ? 1 : 0
  route_table_id = aws_route_table.nat_gw_1b[count.index].id
  subnet_id      = aws_subnet.private_b.id
}

# Availability Zone A - Publically accessible
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_a_subnet_cidr_block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "public_${lower(var.app_name)}_a"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
    Tier      = "Public"
    AZ        = "A"
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Availability Zone B - Publically accessible
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_b_subnet_cidr_block
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name      = "public_${lower(var.app_name)}_b"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
    Tier      = "Public"
    AZ        = "B"
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Availability Zone A - NOT Publically accessible
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_a_subnet_cidr_block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name      = "private_${lower(var.app_name)}_a"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
    Tier      = "Private"
    AZ        = "A"
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# Availability Zone B - NOT Publically accessible
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_b_subnet_cidr_block
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false
  tags = {
    Name      = "private_${lower(var.app_name)}_b"
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
    Tier      = "Private"
    AZ        = "B"
  }

  lifecycle {
    ignore_changes = [ tags ["Name"], tags["Customer"] ] //don't mess with names or CUSTOMER values once created
  }
}

# A default security group to access instances over RDP and WINRM
resource "aws_security_group" "remote_access" {
  name        = "Instance RDP and WINRM access"
  description = "Allows RDP access from anywhere, and WINRM internally"
  vpc_id      = aws_vpc.main.id

  # RDP access from anywhere (has no effect within private subnet deployments, will just be VPC local)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WINRM access from the VPC
  ingress {
    from_port   = 5985
    to_port     = 5985
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
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

# A default security group to access instances over SSH
resource "aws_security_group" "remote_access_ssh" {
  name        = "Instance SSH"
  description = "Allows SSH access from anywhere"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere (has no effect within private subnet deployments, will just be VPC local)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

# A default security group to access instances over UDP 6000-6100 (for media, e.g. SRT)
resource "aws_security_group" "remote_access_udp_6000_6100" {
  name        = "Media UDP"
  description = "Allows UDP 6000-6100 access from anywhere, for media streaming"
  vpc_id      = aws_vpc.main.id

  # UDP access on port 6000-6100 from anywhere (has no effect within private subnet deployments, will just be VPC local)
  ingress {
    from_port   = 6000
    to_port     = 6100
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

# A default security group with all internal ports open
resource "aws_security_group" "open_internal" {
  name        = "Instance VPC internal open access"
  description = "Allows any traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
    Env       = var.environment_name
    App       = var.app_name
    CUSTOMER  = var.customer_tag
    Terraform = true
  }
}

/*
# Get PEM details from AWS secrets and create AWS public key registration for use by any VM instances
data "aws_secretsmanager_secret" "privatekey" {
  arn = var.aws_secrets_privatekey_arn
}

data "aws_secretsmanager_secret_version" "privatekey" {
  secret_id = data.aws_secretsmanager_secret.privatekey.id
}

data "tls_public_key" "terraform_key" {
  private_key_pem = data.aws_secretsmanager_secret_version.privatekey.secret_string
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key-${var.app_name}-${var.environment_name}"
  public_key = data.tls_public_key.terraform_key.public_key_openssh
}

#store a file in the state bucket for use as a base Cinegy Agent manifest template 
  resource "aws_s3_bucket_object" "default_base_manifest" {
  bucket       = var.state_bucket
  provider     = aws.state
  key          = "${var.environment_name}/vpc/default_base_manifest.txt"
  source       = var.cinegy_agent_default_manifest_path
  content_type = "text/plain"  
  server_side_encryption = "AES256"
}

*/