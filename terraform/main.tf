locals {
  project = "pod-metadata"

}

module "vpc" {
  source = "./modules/vpc/"

  project = local.project
}

module "eks" {
  source = "./modules/eks/"

  project            = local.project
  vpc_id             = module.vpc.vpc_id
  cluster_version    = "1.36"
  cluster_subnet_ids = module.vpc.cluster_subnet_ids
  ng_subnet_ids      = module.vpc.ng_subnet_ids
}