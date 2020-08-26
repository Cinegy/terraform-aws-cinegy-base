
variable "amazon_owned_ami_name" {
  description = "An AMI name (wildcards supported) for selecting the base image for the VM"
  default     = "Windows_Server-2016-English-Full-Base*"
}

variable "root_volume_size" {
  description = "Size in GB to allocate to OS drive"
  default     = 45
}

variable "instance_type" {
  description = "Required instance type for server"
  default     = "t3.small"
}

variable "aws_subnet_tier" {
  description = "Tier of subnet for deployment (Private / Public)"
  default     = "Private"
}

variable "aws_subnet_az" {
  description = "Availability Zone for deployment (A/B/...)"
  default     = "A"
}

variable "host_name_prefix" {
  description = "Prefix value to use in Hostname metadata tag (e.g. CIS1A)"
  default     = "WINDOWS1A"
}

variable "host_description" {
  description = "Prefix description to use in Name metadata tag (e.g. Cinegy Identity Service (CIS) 01)"
  default     = "Default Windows VM"
}

variable "attach_data_volume" {
  description = "Attach a secondary data volume to the host (default false)"
  default     = false
}

variable "data_volume_size" {
  description = "Size of any secondary data volume (default 30GB)"
  default     = "30"
}

variable "allow_open_rdp_access" {
  description = "Allow world-access to RDP ports (default false)"
  default     = false
}

variable "allow_all_internal_traffic" {
  description = "Allow all internal network traffic (default false)"
  default     = false
}

variable "allow_media_udp_ports_externally" {
  description = "Opens UDP media streaming ports for external access (default false)"
  default     = false
}

variable "create_external_dns_reference" {
  description = "Create a DNS entry for the public IP of the VM inside the default Route53 zone (default false)"
  default     = false
}

variable "customer_tag" {
  description = "Tag to identify a resource as associated to a specific customer"
  default = null
}

variable "user_data_script_extension" {
  description = "Extended element to attach to core user data script. Default installs Cinegy Agent with base elements and renames host to match metadata name tag."
  default     = <<EOF
  InstallAgent
  AddDefaultPackages
  RenameHost
EOF
}

variable "tenancy" {
  description = "Instance tenancy mode (can be default, dedicated or host)"
  default     = "default"
}

