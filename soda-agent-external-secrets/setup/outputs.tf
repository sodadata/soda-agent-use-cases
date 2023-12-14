output "vault_root_token" {
  value     = data.http.vault_init.response_body
  sensitive = true
}

output "cluster_name" {
  value = var.cluster_name
}

output "base_port" {
  value = var.base_port
}

output "cluster_admin_token" {
  sensitive = true
  value     = kubernetes_secret_v1.cluster_admin_token.data.token
}

output "soda_agent_namespace" {
  sensitive = false
  value     = var.soda_agent_namespace
}

output "vault_access" {
  sensitive = false
  value     = "http://127.0.0.1:${tostring(local.vault_port)}"
}

output "vault_init_access" {
  sensitive = false
  value     = "http://127.0.0.1:${tostring(local.vault_init_port)}"
}

output "dashboard_access" {
  sensitive = false
  value     = "http://127.0.0.1:${tostring(local.headlamp_port)}"
}
