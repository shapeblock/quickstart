locals {
  kubeconfig = yamldecode(var.kubeconfig)
}

provider "kubernetes" {
  host = local.kubeconfig.clusters.0.cluster.server

  client_certificate     = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
}

provider "kubectl" {
  host = local.kubeconfig.clusters.0.cluster.server

  client_certificate     = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users.0.user.client-key-data)
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
}

provider "helm" {
  kubernetes {
    host = local.kubeconfig.clusters.0.cluster.server

    client_certificate     = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
    client_key             = base64decode(local.kubeconfig.users.0.user.client-key-data)
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
  }
}

resource "kubernetes_namespace" "shapeblock" {
  metadata {
    name = "shapeblock"
  }
}


resource "helm_release" "ingress" {
  name       = "nginx-ingress"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  version    = "11.3.18"
  namespace  = "shapeblock"
  timeout    = 600
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cert-manager"
  version    = "1.3.16"
  namespace  = "cert-manager"
  set {
    name  = "installCRDs"
    value = true
  }
  timeout    = 600
  create_namespace = true
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body  = templatefile("${path.module}/cert-issuer.yaml.tpl", { email = var.email })
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "kpack" {
  name       = "kpack"
  repository = "https://shapeblock.github.io"
  chart      = "sb-kpack"
  version    = "0.1.7"
  namespace  = "shapeblock"
}

data "kubectl_path_documents" "kpack_manifests" {
  pattern = "${path.module}/kpack/*.yaml"
}

resource "kubectl_manifest" "cluster_stores" {
  count      = length(data.kubectl_path_documents.kpack_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.kpack_manifests.documents, count.index)
  depends_on = [helm_release.kpack]
}


resource "helm_release" "helm_operator" {
  name       = "helm-operator"
  chart      = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  version    = "2.13.0"
  namespace  = "shapeblock"

  set {
    name  = "imageautomationcontroller.create"
    value = false
  }

  set {
    name  = "imagereflectorcontroller.create"
    value = false
  }

  set {
    name  = "kustomizecontroller.create"
    value = false
  }
}

resource "kubectl_manifest" "sb_repository" {
  yaml_body  = file("${path.module}/sb-repository.yaml")
  depends_on = [helm_release.helm_operator]
}

resource "kubectl_manifest" "bitnami_repository" {
  yaml_body  = file("${path.module}/bitnami-repository.yaml")
  depends_on = [helm_release.helm_operator]
}

data "kubernetes_service" "ingress_controller" {
  metadata {
    name      = "nginx-ingress-nginx-ingress-controller"
    namespace = "shapeblock"
  }
  depends_on = [helm_release.ingress]
}


locals {
  ingress_hostname = data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.hostname
  ingress_ip       = data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.ip
}

resource "random_password" "registry_password" {
  length = 30
}

resource "null_resource" "encrypted_registry_password" {
  triggers = {
    orig = random_password.registry_password.result
    pw   = bcrypt(random_password.registry_password.result)
  }

  lifecycle {
    ignore_changes = [triggers["pw"]]
  }
}

// registry
resource "helm_release" "registry" {
  name       = "registry"
  chart      = "docker-registry"
  repository = "https://helm.twun.io"
  version    = "2.2.3"
  namespace = "shapeblock"

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.size"
    value = "30Gi" //var.registry_storage_size
  }

  set {
    name  = "ingress.enabled"
    value = true
  }

  set {
    name  = "ingress.hosts[0]"
    value = format("registry.%s", var.cluster_dns)
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = format("registry.%s", var.cluster_dns)
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "registry-tls"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/proxy-body-size"
    value = "0"
  }

  set {
    name  = "secrets.htpasswd"
    value = format("admin:%s", null_resource.encrypted_registry_password.triggers["pw"])
  }

  set {
    name  = "updateStrategy.type"
    value = "Recreate"
  }
  depends_on = [kubectl_manifest.cluster_issuer]
}

resource "kubernetes_secret" "container_registry" {
  metadata {
    name      = "registry-creds"
    namespace = "shapeblock"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "registry.${var.cluster_dns}": {
      "auth": "${base64encode("admin:${random_password.registry_password.result}")}"
    }
  }
}
DOCKER
  }
  type  = "kubernetes.io/dockerconfigjson"
}

data "kubectl_path_documents" "sb_manifests" {
  pattern = "${path.module}/crds/*.yaml"
}

// SB service

// Postgres
resource "helm_release" "postgresql" {
  name       = "database"
  namespace  = "shapeblock"
  chart      = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "15.5.20"

  set {
    name  = "auth.database"
    value = var.database_name
  }

  set {
    name  = "auth.username"
    value = var.database_user
  }

  set {
    name  = "auth.password"
    value = var.database_password
  }

  set {
    name  = "auth.postgresPassword"
    value = var.database_admin_password
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "primary.persistence.size"
    value = "2Gi"
  }

  set {
    name  = "tls.enabled"
    value = "true"
  }

  set {
    name  = "tls.autoGenerated"
    value = "true"
  }
}

// Redis
resource "helm_release" "redis" {
  name       = "redis"
  namespace  = "shapeblock"
  chart      = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "19.6.4"

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "master.persistence.size"
    value = "2Gi"
  }
}

resource "random_password" "sb_password" {
  length  = 16
  special = false
  count   = (var.sb_password != null) ? 0 : 1
}

locals {
  sb_password = (var.sb_password != null) ? var.sb_password : random_password.sb_password.0.result
}

locals {
  sb_values = templatefile("${path.module}/sb-values.yaml.tpl", {
    image             = var.sb_image,
    tag               = var.sb_tag,
    secret_key        = var.secret_key,
    github_token      = var.github_token,
    fernet_keys       = var.fernet_keys,
    cluster_dns       = var.cluster_dns,
    database_name     = var.database_name,
    database_user     = var.database_user,
    database_password = var.database_password,
    email             = var.email,
    user              = var.sb_user,
    password          = local.sb_password,
    control_plane_ip  = local.kubeconfig.clusters.0.cluster.server
  })
}

// Backend
resource "helm_release" "shapeblock" {
  name       = "shapeblock"
  namespace  = "shapeblock"
  chart      = "nxs-universal-chart"
  repository = "https://registry.nixys.io/chartrepo/public"
  version    = "2.8.0"

  values     = [local.sb_values]
  depends_on = [helm_release.postgresql, helm_release.redis, kubectl_manifest.cluster_issuer]
}

resource "kubectl_manifest" "shapeblock_crs" {
  count      = length(data.kubectl_path_documents.sb_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.sb_manifests.documents, count.index)
  depends_on = [helm_release.shapeblock]
}

resource "random_uuid" "cluster_uuid" {
}

locals {
  sb_operator_values = templatefile("${path.module}/sb-operator.yaml.tpl", {
    image        = var.sb_operator_image,
    tag          = var.sb_operator_tag,
    sb_url       = "https://sb.${var.cluster_dns}",
    cluster_uuid = random_uuid.cluster_uuid.result,
    namespace    = "shapeblock"
  })
}
// SB operator
resource "kubectl_manifest" "sb_operator" {
  yaml_body  = local.sb_operator_values
  depends_on = [kubectl_manifest.shapeblock_crs]
}
