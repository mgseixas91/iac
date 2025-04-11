resource "aws_s3_bucket" "terraform-bucket-poc-sensedia" {
  bucket = "terraform-bucket-poc-sensedia"
  tags = {
    CreatedBy        = "Terraform"
      }
}
