variable "project" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "cluster_subnet_ids" {
  type        = list(string)
  description = "Cluster subnet ids"
}

variable "ng_subnet_ids" {
  type        = list(string)
  description = "Node group subnet ids"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for EKS cluster and node AMI"
}