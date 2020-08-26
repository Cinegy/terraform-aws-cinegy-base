provider "aws" {
  region  = var.aws_region
  version = "~> 2.47"
}

provider "tls" {
  version = "~> 2.2"
}