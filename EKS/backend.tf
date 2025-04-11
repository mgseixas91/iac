terraform {
  backend "s3" {
    bucket  = "terraform-bucket-poc-sensedia"
    key     = "eks.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}
