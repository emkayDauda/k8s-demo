data "aws_availability_zones" "available" {
  state = "available"
}



# data "kubectl_file_documents" "loadbalancer-manifest" {
#   content = file("service-loadbalancer.yaml")
# }

# resource "kubectl_manifest" "loadbalancer" {
#   depends_on = [kubectl_manifest.deployment]
#   yaml_body  = data.kubectl_file_documents.loadbalancer-manifest.content
#   force_new  = true
# }

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

locals {
  cluster_name = "learnk8s"
}

module "eks-kubeconfig" {
  source  = "hyperbadger/eks-kubeconfig/aws"
  version = "1.0.0"

  depends_on = [module.eks]
  cluster_id = module.eks.cluster_id
}

resource "local_file" "kubeconfig" {
  content  = module.eks-kubeconfig.kubeconfig
  filename = "kubeconfig_${var.cluster_name}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name                 = "k8s-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.24"
  subnet_ids      = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  eks_managed_node_groups = {
    first = {
      desired_capacity = 3
      max_capacity     = 10
      min_capacity     = 2

      instance_types = ["t3.medium"]
      
    }
  }
}

data "kubectl_file_documents" "namespace-manifest" {
  content = file("./manifests/base/00-sock-shop-ns.yaml")
  depends_on = [
    local_file.kubeconfig
  ]
}

resource "kubectl_manifest" "namespace" {
  yaml_body = data.kubectl_file_documents.namespace-manifest.content
  force_new = true
}

data "kubectl_filename_list" "manifests" {
  pattern = "./manifests/app/*.yaml"
}

resource "kubectl_manifest" "services" {
  depends_on = [kubectl_manifest.namespace]
  count      = length(data.kubectl_filename_list.manifests.matches)
  yaml_body  = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}

