module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)

  eks_managed_node_group_defaults = {

    instance_types = ["m7i-flex.large"]

    attach_cluster_primary_security_group = true

  }


  eks_managed_node_groups = {

    tws-demo-ng = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["m7i-flex.large"]
      capacity_type  = "SPOT"

      disk_size                  = 35
      use_custom_launch_template = false # Important to apply disk size!

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }


  node_security_group_additional_rules = {

    ssh = {
      description = "SSH access"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }

    http = {
      description = "HTTP access"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }

    https = {
      description = "HTTPS access"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }

    app_8080 = {
      description = "App / Jenkins"
      protocol    = "tcp"
      from_port   = 8080
      to_port     = 8080
      cidr_blocks = ["0.0.0.0/0"]
      type        = "ingress"
    }
  }


  tags = local.tags


}

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}



