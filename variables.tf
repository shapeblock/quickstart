variable "email" {
  description = "Email used for Lets Encrypt certificate issuer"
}

variable "registry_url" {
  description = "Container registry url. Use \"https://index.docker.io/v1/\" for dockerhub."
}

variable "registry_username" {
  description = "Container registry username"
}

variable "registry_password" {
  description = "Container registry password"
  sensitive   = true
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

variable "sb_user" {
  description = "Shapeblock backend user"
  default     = "admin"
}

variable "sb_password" {
  description = "Shapeblock backend user password"
  default     = null
  sensitive   = true
}


variable "database_name" {
  description = "Shapeblock DB name"
  default     = "shapeblock"
}

variable "database_user" {
  description = "Shapeblock DB user"
  default     = "shapeblock"
}

variable "database_password" {
  description = "Shapeblock DB password"
  default     = "shapeblock"
  sensitive   = true
}

variable "database_admin_password" {
  description = "Shapeblock DB  admin password"
  default     = "shapeblock"
  sensitive   = true
}

variable "github_token" {
  description = "Github token for reading contents of public repos."
  sensitive   = true
}
