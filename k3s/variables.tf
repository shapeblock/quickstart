variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "nodes" {
  type = list(object({
    name = string
    ip   = string
  }))
  description = "Cluster nodes"
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "root"
}

variable "ssh_port" {
  description = "SSH port"
  type        = string
  default     = "22"
}

variable "ssh_key" {
  description = "SSH private key as a string"
  type        = string
}

variable "kubernetes_version" {
  description = "kubernetes version to install"
  type        = string
}
