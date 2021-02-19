# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "aws_account_id" {
  description = "AWS account ID, used when constructing ARNs for API Gateway."
}

variable "state_bucket" {
  description = "Name of bucket used to hold state."
}

variable "state_region" {
  description = "Region associated with state bucket."
  default     = "us-west-2"
}

variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "app_name" {
  description = "Name to used to label application deployment, for example 'central' or 'air'."
}

variable "aws_secrets_generic_account_password_arn" {
  description = "ARN representing general password secret stored within AWS Secrets Manager"
}

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private PEM key secret stored within AWS Secrets Manager"
}

variable "dynamodb_table" {
  description = "DynamoDB table used for controlling terragrunt locks"
}

variable "shared_route53_zone_id" {
  description = "Zone ID of the default shared route 53 zone used to make helper entries (e.g. sysadmin DNS entries)"
  default     = ""
}

variable "shared_route53_zone_suffix" {
  description = "Suffix to append to Route 53 generated entries, should match the value defined inside the Route53 default zone (e.g. terraform.cinegy.net)"
  default     = ""
}

# Module specific variables

variable "instance_type" {
  description = "Required instance type for server"
}

variable "aws_subnet_tier" {
  description = "Tier of subnet for deployment (Private / Public)"
}

variable "aws_subnet_az" {
  description = "Availability Zone for deployment (A/B/...)"
}

variable "host_name_prefix" {
  description = "Prefix value to use in Hostname metadata tag (e.g. CIS1A)"
}

variable "host_description" {
  description = "Prefix description to use in Name metadata tag (e.g. Cinegy Identity Service (CIS) 01)"
}

variable "attach_data_volume" {
  description = "Attach a secondary data volume to the host (default false)"
  default     = false
}

variable "data_volume_size" {
  description = "Size of any secondary data volume (default 30GB)"
  default     = "30"
}

variable "allow_all_internal_traffic" {
  description = "Allow all internal network traffic (default false)"
  default     = false
}

variable "create_external_dns_reference" {
  description = "Create a DNS entry for the public IP of the VM inside the default Route53 zone (default false)"
  default     = false
}

variable "create_internal_dns_reference" {
  description = "Create a DNS entry for the private IP of the VM inside the default Route53 zone (default false)"
  default     = false
}

variable "internal_dns_name" {
  description = "Internal name to use for DNS record - if empty, auto-generates"
  default     = ""
}

# variable "userdata_script_path" {
#   description = "Path to the user-data script to inject into the VM"
# }

variable "instance_role_name" {
  description = "IAM instance role name to attach to the EC2 instance"
  default = ""
}

variable "amazon_owned_ami_name" {
  description = "An AMI name (wildcards supported) for selecting the base image for the VM"
  default     = "ubuntu-bionic-18.04-amd64-server-*"
}

variable "root_volume_size" {
  description = "Size in GB of EBS volume to attach as the root disk size (default 8)"
  default = 8
}

variable "customer_tag" {
  description = "Tag to identify a resource as associated to a specific customer"
  default = null
}

variable "instance_subnet" {
  description = "Target subnet for attachment of instance"
}

variable "security_groups" {
  description = "Array of security group IDs to attach to the instance"
  default = []
}
