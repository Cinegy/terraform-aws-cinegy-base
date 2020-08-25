# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "app_name" {
  description = "Name to used to label application deployment, for example 'central' or 'air'."
}

# Module specific variables
variable "cidr_block" {
  description = "IP range in CIDR format for VPC usage"
}

variable "public_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}

variable "public_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}

variable "private_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}

variable "private_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}

variable "secondary_az_enabled" {
  description = "Value indicating if resources should create or use a secondary AZ (HA modes)"
  default = false
}

variable "customer_tag" {
  description = "Tag to identify a resource as associated to a specific customer"
  default = null
}

/*
variable "cinegy_agent_default_manifest_path" {
  description = "Path to a file containing the defaults to use when creating an Cinegy Agent manifest file"
  default     = "./conf/defaultproducts.manifest"
}
*/