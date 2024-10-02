terraform {
  backend "s3" {
    bucket         = "end-to-end-three"
    region         = "eu-west-1"
    key            = "tfkey"
    dynamodb_table = "three-tier-files"
    encrypt        = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}