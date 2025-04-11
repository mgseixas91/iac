data "aws_caller_identity" "current" {}

locals {
  tags = {
    Recurso = "Cluster EKS"
    Ambiente = "POC"
    Devops = "Mario Seixas"
    Projeto = "POC"
    Terraform = "TRUE"  
  }

  vpc_id     = "vpc-0d877f50ca800aea8"
  subnet_ids = ["subnet-071d0a1ac89f94fc4", "subnet-0b69d19fab80e6e9e"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cloudwatch_log_group_retention_in_days = 0

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = "arn:aws:kms:us-east-1:577125335739:key/6b4b1872-920f-488f-ada3-d12c4cd0a679"
  }

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  cluster_security_group_additional_rules = {
    egress_all = {
      description = "cluster all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_node_security_group_all = {
      description                = "node to cluster all ports/protocols"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "ingress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_security_group_all = {
      description                   = "cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # AWS EKS Managed Node Group
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["t3.micro"]
  }

  eks_managed_node_groups = {
    poc-sensedia = {
      min_size     = 1
      max_size     = 4
      desired_size = 4

      instance_types = ["t3.micro"]
    }
  }

  # aws-auth configmap
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true
  aws_auth_roles = [  ]
  aws_auth_users = [ ]
  aws_auth_accounts = []

  # irsa
  enable_irsa = true

  tags = merge(
    {
      Name = var.cluster_name
    },
    local.tags
  )
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.1"

  role_name                        = var.cluster_autoscaler_controller_irsa_name
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = merge(
    {
      Name = var.cluster_autoscaler_controller_irsa_name
    },
    local.tags
  )
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.1"

  role_name             = var.vpc_cni_irsa_name
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = merge(
    {
      Name = var.vpc_cni_irsa_name
    },
    local.tags
  )
}
