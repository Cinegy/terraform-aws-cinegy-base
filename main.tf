terraform {
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.44.0, < 4.0.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1, < 4.0"
    }

  }
}