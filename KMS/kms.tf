provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "eks_poc" {
  description             = "KMS key for EKS POC"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks_poc_alias" {
  name          = "alias/eks-poc"
  target_key_id = aws_kms_key.eks_poc.key_id
}
