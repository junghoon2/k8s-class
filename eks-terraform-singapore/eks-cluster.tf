provider "aws" {
  region = local.region
}

locals {
  name            = "jerry-test-01"
  cluster_version = "1.24"
  region          = "ap-southeast-1"

  tags = {
    env        = "dev"
    user       = "jerry" 
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_type      = "AL2_x86_64"

    # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1986
    create_cluster_primary_security_group_tags = false
    create_security_group = true

    cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
    vpc_security_group_ids = [
      module.eks.cluster_security_group_id,
    ]

    disable_api_termination = false
    enable_monitoring       = true

    # We are using the IRSA created below for permissions 
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster) 
    # and then turn this off after the cluster/node group is created. Without this initial policy, 
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster 
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context 
    
    # iam_role_attach_cni_policy = false
    iam_role_attach_cni_policy = true

    ebs_optimized           = true
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          # encrypted             = true
          # kms_key_id            = aws_kms_key.ebs.arn
          delete_on_termination = true
        }
      }
    }
    tags = local.tags
    enable_irsa = true
  }

  eks_managed_node_groups = {
    base = {    
      name          = "base"  
      use_name_prefix = false

      instance_types = ["t2.large", "t3.large", "t3a.large", "m6i.large"]
      capacity_type  = "SPOT"

      min_size     = 3
      max_size     = 10
      desired_size = 3

      subnet_ids = module.vpc.public_subnets
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>3.12"

  name                 = local.name
  cidr                 = "10.102.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.102.0.0/22", "10.102.4.0/22", "10.102.8.0/22"]
  public_subnets       = ["10.102.12.0/22", "10.102.16.0/22", "10.102.20.0/22"]

  create_egress_only_igw          = true

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = local.tags

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix      = "vpc_cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}