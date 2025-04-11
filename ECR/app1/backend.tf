terraform {
  backend "s3" {
    bucket  = "	terraform-bucket-poc-sensedia"
    key     = "app1/ecr.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}
