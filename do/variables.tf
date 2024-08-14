variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "region" {
  description = "Cloud provider region"
  type        = string
}

variable "image" {
  type        = string
  default     = "ubuntu-24-04-x64"
  description = "Base image for the VMs"
}

variable "nodes" {
  type = list(object({
    name = string
    size = string
  }))
  description = "Cluster nodes config"
}

variable "kubernetes_version" {
  description = "kubernetes version to install"
  type        = string
}

// SB stuff
variable "email" {
  description = "Email used for Lets Encrypt certificate issuer"
}

// Can be generated at https://djecrety.ir/
variable "secret_key" {
  description = "Backend App secret key"
  sensitive   = true
}

// Can be generated at https://fernetkeygen.com/
variable "fernet_keys" {
  description = "Used to encrypt secrets at rest in the backend."
  sensitive   = true
}

variable "cluster_dns" {
  description = "wildcard cluster level dns."
  default     = null
}

variable "github_token" {
  description = "Github token for reading contents of public repos."
  sensitive   = true
}

variable "sb_image" {
  description = "Shapeblock image repo"
  default     = "ghcr.io/shapeblock/backend"
}

variable "sb_tag" {
  description = "Shapeblock image tag"
  default     = "v1.0.0"
}

variable "sb_operator_image" {
  description = "Shapeblock operator image repo"
  default     = "ghcr.io/shapeblock/operator"
}

variable "sb_operator_tag" {
  description = "Shapeblock operator image tag"
  default     = "v1.0.0"
}

variable "debug" {
  type    = bool
  default = true
}
