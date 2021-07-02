# Module specific variables

variable "aws_subnet_tier" {
  description = "Tier of subnet for deployment (Private / Public)"
  default = "Private"
}

variable "aws_subnet_az" {
  description = "Availability Zone for deployment (A/B/...)"
  default = "A"
}

variable "rds_instance_class" {
  description = "Required instance class for RDS server"
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  default     = "false"
}

variable "rds_allocated_storage" {
  description = "The allocated storage in gigabytes"
  default     = "20"
}

variable "rds_skip_final_snapshot" {
  description = "Specifies if a final snapshot should be created upon RDS destruction"
  default     = false
}

variable "mssql_engine" {
  description = "AWS RDS string matching the MSSQL engine type to instance (e.g. sqlserver-ex)"
  default     = "sqlserver-ex"
}

variable "mssql_engine_family" {
  description = "AWS RDS string matching the MSSQL engine family to instance (e.g. sqlserver-ex-13.0)"
  default     = "sqlserver-ex-13.0"
}

variable "engine_major_version" {
  description = "AWS RDS string matching the MSSQL engine major version to instance (e.g. 13.00)"
  default     = "13.00"
}

variable "mssql_admin_username" {
  description = "Username for the administrator DB user"
  default     = "sa"
}

variable "rds_instance_name_prefix" {
  description = "Prefix value to use when naming created RDS instance (e.g. CINARC1)"
}

variable "domain_join" {
  description = "Join RDS instance to AD (default false)"
  default = false
}
