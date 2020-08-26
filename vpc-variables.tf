# Module specific variables
variable "cidr_block" {
  description = "IP range in CIDR format for VPC usage"
  default = "10.120.0.0/16"
}

variable "public_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
  default = "10.120.1.0/24"
}

variable "public_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
  default = "10.120.2.0/24"
}

variable "private_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
  default = "10.120.101.0/24"
}

variable "private_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
  default = "10.120.102.0/24"
}

variable "secondary_az_enabled" {
  description = "Value indicating if resources should create or use a secondary AZ (HA modes)"
  default = false
}


/*
variable "cinegy_agent_default_manifest_path" {
  description = "Path to a file containing the defaults to use when creating an Cinegy Agent manifest file"
  default     = "./conf/defaultproducts.manifest"
}
*/