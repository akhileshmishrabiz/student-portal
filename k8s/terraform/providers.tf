terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.56"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}