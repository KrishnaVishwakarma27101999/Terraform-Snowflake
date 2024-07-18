terraform {
  # required_version = "~>1.7.3"
  
  backend "s3" {     # # Note : backend variable cannot be parametrized
    encrypt = true
    # bucket = "indy-s3-dev-tf-state"
    # key = "state/terraform.tfstate"
    # region = "eu-west-2"
  }

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~>0.87"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.43.0"
    }
  }
}

