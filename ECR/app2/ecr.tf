resource "aws_ecr_repository" "app1-repository" {
  image_tag_mutability = "MUTABLE"
  name                 = "app2"
  tags = {
    "Enviroment" = "poc"
    "Name"       = "app2"
    "Terraform"  = "true"
  }
  tags_all = {
    "Enviroment" = "poc"
    "Name"       = "app2"
    "Terraform"  = "true"
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
