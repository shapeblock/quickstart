terraform {
  required_providers {
    yoshik3s = {
      source  = "HideyoshiNakazone/yoshik3s"
      version = "1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    remote = {
      source  = "tmscer/remote"
      version = "0.2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.0"
    }
  }
}

locals {
  master_ip    = var.nodes.0.ip
  worker_nodes = slice(var.nodes, 1, length(var.nodes))
}

resource "random_id" "k3s_token" {
  byte_length = 64
}

resource "yoshik3s_cluster" "kubernetes_cluster" {
  name        = var.cluster_name
  token       = random_id.k3s_token.b64_std
  k3s_version = var.kubernetes_version
}

resource "yoshik3s_master_node" "master_node" {
  cluster = yoshik3s_cluster.kubernetes_cluster

  node_connection = {
    host        = local.master_ip
    port        = var.ssh_port
    user        = var.ssh_user
    private_key = var.ssh_key
  }

  node_options = [
    "--disable traefik",
  ]
}

resource "time_sleep" "wait_30_seconds_master" {
  depends_on      = [yoshik3s_master_node.master_node]
  create_duration = "30s"
}

resource "yoshik3s_worker_node" "worker_nodes" {
  master_server_address = local.master_ip

  cluster = yoshik3s_cluster.kubernetes_cluster

  for_each = {
    for worker_node in local.worker_nodes : worker_node.name => worker_node
  }

  node_connection = {
    host        = each.value.ip
    port        = var.ssh_port
    user        = var.ssh_user
    private_key = var.ssh_key
  }

  node_options = [
    "--node-label node_type=worker",
  ]
  depends_on = [time_sleep.wait_30_seconds_master]
}

resource "null_resource" "fetch_kubeconfig" {
  provisioner "remote-exec" {
    connection {
      host        = local.master_ip
      user        = "root"
      private_key = var.ssh_key
    }

    inline = [
      "sed 's|https://127.0.0.1:6443|https://${local.master_ip}:6443|g' /etc/rancher/k3s/k3s.yaml > /root/kubeconfig.yaml"
    ]
  }
  depends_on = [time_sleep.wait_30_seconds_master]
}

data "remote_file" "kubeconfig" {
  conn {
    host        = local.master_ip
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.ssh_key
  }

  path       = "/root/kubeconfig.yaml"
  depends_on = [null_resource.fetch_kubeconfig]
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = data.remote_file.kubeconfig.content
}
