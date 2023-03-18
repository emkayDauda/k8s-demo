variable "cluster_name" {
  default = "altschool-final-exam-cluster"
  type    = string
}

variable "cluster_version" {
  default = "1.24"
  type    = string
}

variable "eks_auth_users" {
  type    = list(string)
  default = ["716239669288"]
}

variable "region" {
 type =  string
 default = "us-east-1"
}