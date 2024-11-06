module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "test-project-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }



  vpc_id                   = aws_vpc.main.id
  subnet_ids               = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]


  eks_managed_node_groups = {
 amc-cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
  }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
