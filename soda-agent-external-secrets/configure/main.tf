locals {
  soda_agent_namespace = data.terraform_remote_state.setup.outputs.soda_agent_namespace
}

module "vault_configuration" {
  source = "../modules/vault"

  vault_token = data.terraform_remote_state.setup.outputs.vault_root_token

  providers = {
    vault = vault
  }
}

resource "vault_kv_secret_v2" "example" {
  mount               = module.vault_configuration.vault_kvv2_path
  name                = "local/soda"
  delete_all_versions = true
  data_json = jsonencode(
    {
      POSTGRES_USERNAME = "nyc",
      POSTGRES_PASSWORD = "nyc"
    }
  )
}

resource "kubernetes_secret" "external_secrets_vault_token" {
  metadata {
    name      = "external-secrets-vault-token"
    namespace = "external-secrets"
  }

  data = {
    vaultToken = module.vault_configuration.read_only_token
  }
}

resource "kubernetes_secret" "external_secrets_vault_app_role_secret_id" {
  metadata {
    name      = "external-secrets-vault-app-role-secret-id"
    namespace = "external-secrets"
  }

  data = {
    appRoleSecretId = module.vault_configuration.read_only_role_secret_id
  }
}

resource "kubectl_manifest" "external_secrets_cluster_secret_store_vault_token" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-token
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "${module.vault_configuration.vault_kvv2_path}"
      version: "v2"
      auth:
        tokenSecretRef:
          key: vaultToken
          name: "${kubernetes_secret.external_secrets_vault_token.metadata[0].name}"
          namespace: "${kubernetes_secret.external_secrets_vault_token.metadata[0].namespace}"
YAML
}

resource "kubectl_manifest" "external_secrets_cluster_secret_store_vault_app_role" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-app-role
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "${module.vault_configuration.vault_kvv2_path}"
      version: "v2"
      auth:
        appRole:
          path: ${module.vault_configuration.vault_app_role_path}
          roleId: ${module.vault_configuration.read_only_role_id}
          secretRef:
            key: appRoleSecretId
            name: "${kubernetes_secret.external_secrets_vault_app_role_secret_id.metadata[0].name}"
            namespace: "${kubernetes_secret.external_secrets_vault_app_role_secret_id.metadata[0].namespace}"
YAML
}

resource "kubectl_manifest" "externalsecret_soda_agent" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: soda-agent
  namespace: ${local.soda_agent_namespace}
spec:
  data:
    - remoteRef:
        key: local/soda
        property: POSTGRES_USERNAME
      secretKey: POSTGRES_USERNAME
    - remoteRef:
        key: local/soda
        property: POSTGRES_PASSWORD
      secretKey: POSTGRES_PASSWORD
  refreshInterval: 1m
  secretStoreRef:
    kind: ClusterSecretStore
    name: ${kubectl_manifest.external_secrets_cluster_secret_store_vault_app_role.name}
  target:
    name: soda-agent-secrets
    template:
      data:
        soda-agent.conf: |
          POSTGRES_USERNAME={{ .POSTGRES_USERNAME }}
          POSTGRES_PASSWORD={{ .POSTGRES_PASSWORD }}
      engineVersion: v2
YAML
}
