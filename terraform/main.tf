# Fetch existing IAM Role for EKS Cluster Control Plane
data "aws_iam_role" "cluster" {
  name = "AmazonEKSAutoClusterRole"
}

# EKS Cluster Control Plane
resource "aws_eks_cluster" "main" {
  name     = "python-app-cluster"
  role_arn = data.aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
  }
}

# Fetch existing IAM Role for Worker Nodes
data "aws_iam_role" "node_group" {
  name = "AmazonEKSAutoNodeRole"
}

# Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "standard-workers"
  node_role_arn   = data.aws_iam_role.node_group.arn
  subnet_ids      = aws_subnet.private.*.id

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