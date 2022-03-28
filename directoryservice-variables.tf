variable "ad_enabled" {
  description = "Binary flag to enable AD (or not) within this base environment"
  default     = false
}

variable "domain_name" {
  description = "Active Directory Domain Name - not recommended to keep default, just provided for reference"
  default     = "ad.cinegy.local"
}

variable "directory_type" {
  description = "Directory type to create - can be SimpleAD or MicrosoftAD (default SimpleAD)"
  default     = "SimpleAD"  
}

variable "directory_edition" {
  description = "Directory edition to instance, applies only to MS AD instances (default null, creates a cheaper and quicker simple AD, can be 'Standard' or 'Enterprise' for MS)"
  default     = null
}

variable "domain_admin_password" {
    description = "Domain admin password - sensitive value, recommended to be passed in via environment variables - default provided really for when AD is not enabled"
    default     = "changeme1!"
    type        = string
}