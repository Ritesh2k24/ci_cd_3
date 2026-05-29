# =====================================================================
# 1. VPC MODULE (With Crucial Load Balancer Auto-Discovery Tags)
# =====================================================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "python-app-vpc"
  cidr = "10.0.0.0/16"

  # Uses the region variable from variables.tf to dynamically map AZs
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  # These tags allow AWS to automatically provision public/private ELBs
  public_subnet_tags = {
    "kubernetes.io/cluster/python-app-cluster" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/python-app-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# =====================================================================
# 2. EKS CLUSTER CONTROL PLANE
# =====================================================================
# Fetch existing IAM Role for EKS Cluster Control Plane
data "aws_iam_role" "cluster" {
  name = "AmazonEKSAutoClusterRole"
}

resource "aws_eks_cluster" "main" {
  name     = "python-app-cluster"
  role_arn = data.aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    # Stitched: Combines the public and private subnets output from the VPC module
    subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  }
}

# =====================================================================
# 3. MANAGED NODE GROUP
# =====================================================================
# Fetch existing IAM Role for Worker Nodes
data "aws_iam_role" "node_group" {
  name = "AmazonEKSAutoNodeRole"
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "standard-workers"
  node_role_arn   = data.aws_iam_role.node_group.arn
  
  # Stitched: Places worker nodes safely inside the private subnets managed by the module
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t3.medium"]
}