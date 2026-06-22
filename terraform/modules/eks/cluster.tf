locals {
  addons = [
    {
      name    = "eks-pod-identity-agent"
      version = "v1.3.10-eksbuild.3"
    },
    {
      name    = "eks-node-monitoring-agent"
      version = "v1.6.5-eksbuild.1"
    },
    {
      name    = "kube-proxy"
      version = "v1.35.3-eksbuild.2"
    },
    {
      name    = "vpc-cni"
      version = "v1.22.1-eksbuild.2"
    },
    {
      name    = "coredns"
      version = "v1.13.2-eksbuild.4"
    },
    {
      name    = "external-dns"
      version = "v0.21.0-eksbuild.5"
    },
    {
      name    = "metrics-server"
      version = "v0.8.1-eksbuild.11"
    },
    {
      name    = "amazon-cloudwatch-observability"
      version = "v6.2.0-eksbuild.1"
    },
    {
      name    = "aws-network-flow-monitoring-agent"
      version = "v1.1.4-eksbuild.1"
    }
  ]
}

resource "aws_eks_cluster" "main" {
  name = "${var.project}-cluster"

  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = var.cluster_subnet_ids
    # security_group_ids = [aws_security_group.cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_role" "cluster" {
  name = "${var.project}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
  ])
  policy_arn = each.value
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_addon" "addons" {
  for_each                    = { for addon in local.addons : addon.name => addon }
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.value.name
  addon_version               = each.value.version #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "OVERWRITE"

}