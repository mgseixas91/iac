terraform {
  backend "s3" {
    bucket = "terraform-bucket-poc-sensedia"
    key    = "kms.key"
    region = "us-east-1"
  }
}
