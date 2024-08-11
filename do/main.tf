terraform {
  required_providers {
    digitalocean = {
      source  = "registry.terraform.io/digitalocean/digitalocean"
      version = "2.40.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.0"
    }
  }
}

resource "random_id" "ssh_key_id" {
  byte_length = 8
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "shapeblock-${random_id.ssh_key_id.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "digitalocean_droplet" "nodes" {
  for_each = {
    for node in var.nodes : node.name => node
  }
  name       = each.value.name
  region     = var.region
  size       = each.value.size
  image      = var.image
  ssh_keys   = [digitalocean_ssh_key.ssh_key.id]
  tags       = ["shapeblock", var.cluster_name, random_id.ssh_key_id.hex]
  monitoring = true
}

locals {
  nodes = [
    for node in digitalocean_droplet.nodes :
    {
      name = node.name
      ip   = node.ipv4_address
    }
  ]
}

// wait for 30s for ssh daemon to boot
resource "time_sleep" "wait_30_seconds_nodes" {
  depends_on      = [digitalocean_droplet.nodes]
  create_duration = "30s"
}

module "k3s" {
  source             = "../k3s"
  nodes              = local.nodes
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  ssh_key            = tls_private_key.ssh_key.private_key_openssh
  depends_on         = [time_sleep.wait_30_seconds_nodes]
}

module "shapeblock" {
  source            = "../shapeblock"
  kubeconfig        = module.k3s.kubeconfig
  email             = var.email
  registry_url      = var.registry_url
  registry_username = var.registry_username
  registry_password = var.registry_password
  secret_key        = var.secret_key
  fernet_keys       = var.fernet_keys
  github_token      = var.github_token
  cluster_dns       = var.cluster_dns
  sb_image          = var.sb_image
  sb_tag            = var.sb_tag
  sb_operator_image = var.sb_operator_image
  sb_operator_tag   = var.sb_operator_tag
}

// debug artifacts
resource "local_file" "private_key" {
  filename = "${path.module}/private-key"
  content  = tls_private_key.ssh_key.private_key_pem
  count    = var.debug ? 1 : 0
}

# Set the file permissions to 400
resource "null_resource" "set_permissions" {
  depends_on = [local_file.private_key.0]

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/private-key"
  }
}

// debug artifacts
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = module.k3s.kubeconfig
  count    = var.debug ? 1 : 0
}
