terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #shared_config_files      = ["/Users/tf_user/.aws/conf"]
  shared_credentials_files = ["~/.aws/credentials"]
  #shared_credentials_files = ["/Users/tf_user/.aws/creds"]
  profile = "dipo-vs-aws-terraform"
}