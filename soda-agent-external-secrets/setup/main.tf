locals {
  vault_port      = var.base_port
  vault_init_port = var.base_port + 1
  headlamp_port   = var.base_port + 2
}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      extra_port_mappings {
        container_port = local.vault_port
        host_port      = local.vault_port
      }
      extra_port_mappings {
        container_port = local.vault_init_port
        host_port      = local.vault_init_port
      }
      extra_port_mappings {
        container_port = local.headlamp_port
        host_port      = local.headlamp_port
      }
    }
  }
}

resource "helm_release" "external_secrets" {
  chart            = "external-secrets"
  create_namespace = true
  name             = "external-secrets"
  namespace        = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  version          = "0.8.3"

  depends_on = [kind_cluster.this]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_persistent_volume_claim" "vault_init" {
  wait_until_bound = false
  metadata {
    name      = "vault-init"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"
    resources {
      requests = {
        storage = "128Mi"
      }
    }
  }

  depends_on = [kind_cluster.this]
}

resource "helm_release" "vault" {
  chart            = "vault"
  create_namespace = true
  name             = "vault"
  namespace        = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  version          = "0.24.1"
  wait             = true

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePort"
    value = local.vault_port
  }

  values = [
    file("vault.yaml")
  ]

  depends_on = [kubernetes_persistent_volume_claim.vault_init]
}

resource "kubernetes_namespace" "soda_agent" {
  metadata {
    name = "soda-agent"
  }
}

resource "helm_release" "postgresql" {
  chart            = "postgresql"
  create_namespace = false
  name             = "sodademonyc"
  namespace        = kubernetes_namespace.soda_agent.metadata[0].name
  repository       = "https://charts.bitnami.com/bitnami"
  version          = "12.8.0"
  wait             = true
  values           = [file("${path.module}/postgresql.yaml")]
}

resource "helm_release" "headlamp" {
  chart            = "headlamp"
  create_namespace = true
  name             = "headlamp"
  namespace        = "headlamp"
  repository       = "https://headlamp-k8s.github.io/headlamp/"
  version          = "0.14.0"
  wait             = "true"
}

resource "kubernetes_service" "headlamp" {
  metadata {
    name      = "headlamp-node-port"
    namespace = helm_release.headlamp.namespace
  }
  spec {
    selector = {
      "app.kubernetes.io/instance" = "headlamp"
      "app.kubernetes.io/name"     = "headlamp"
    }
    port {
      name        = "headlamp-node-port"
      node_port   = local.headlamp_port
      port        = 80
      target_port = "http"
    }

    type = "NodePort"
  }

  depends_on = [helm_release.headlamp]
}

resource "kubernetes_service" "vault_init" {
  metadata {
    name      = "vault-init"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/instance" = "vault"
      "app.kubernetes.io/name"     = "vault"
      component                    = "server"
    }
    port {
      name        = "vault-init"
      node_port   = local.vault_init_port
      port        = 6565
      target_port = "vault-init"
    }

    type = "NodePort"
  }

  depends_on = [helm_release.vault]
}

data "http" "vault_init" {
  url = "http://localhost:${local.vault_init_port}/rootToken"
  retry {
    attempts = 3
  }

  depends_on = [
    kubernetes_service.vault_init,
    helm_release.postgresql
  ]
}

resource "kubernetes_secret_v1" "cluster_admin_token" {
  metadata {
    name      = "headlamp-cluster-admin"
    namespace = helm_release.headlamp.namespace
    annotations = {
      "kubernetes.io/service-account.name"      = "headlamp-cluster-admin"
      "kubernetes.io/service-account.namespace" = helm_release.headlamp.namespace
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_service_account" "cluster_admin" {
  metadata {
    name      = "headlamp-cluster-admin"
    namespace = helm_release.headlamp.namespace
  }
}

resource "kubernetes_cluster_role_binding" "cluster_admin" {
  metadata {
    name = "headlamp-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_admin.metadata[0].name
    namespace = kubernetes_service_account.cluster_admin.metadata[0].namespace
  }
}
