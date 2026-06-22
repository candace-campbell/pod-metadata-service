terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.51.0"
    }
  }

  backend "s3" {
    bucket       = "pod-metadata-display-backend"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

