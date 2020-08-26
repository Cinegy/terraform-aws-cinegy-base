# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "app_name" {
  description = "Name to used to label application deployment, for example 'playout' or 'customer-x'."
}

variable "customer_tag" {
  description = "Tag to identify a resource as associated to a specific customer"
  default = null
}