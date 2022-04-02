terraform {
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0, < 5.0.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1, < 4.0"
    }

  }
}