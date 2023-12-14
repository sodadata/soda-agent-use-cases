output "read_only_token" {
  sensitive = true
  value     = vault_token.read_only.client_token
}

output "read_only_role_id" {
  sensitive = false
  value     = vault_approle_auth_backend_role.read_only.role_id
}

output "read_only_role_secret_id" {
  sensitive = true
  value     = vault_approle_auth_backend_role_secret_id.read_only.secret_id
}

output "vault_token" {
  sensitive = true
  value     = var.vault_token
}

output "vault_kvv2_path" {
  sensitive = false
  value     = vault_mount.kvv2.path
}

output "vault_app_role_path" {
  sensitive = false
  value     = vault_auth_backend.approle.path
}

output "admin_username" {
  sensitive = false
  value     = var.admin_username
}

output "admin_password" {
  sensitive = true
  value     = var.admin_password
}

output "read_only_username" {
  sensitive = false
  value     = var.read_only_username
}

output "read_only_password" {
  sensitive = true
  value     = var.read_only_password
}
