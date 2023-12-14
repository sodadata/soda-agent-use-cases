output "vault_read_only_token" {
  sensitive = true
  value     = module.vault_configuration.read_only_token
}

output "vault_read_only_role_id" {
  sensitive = false
  value     = module.vault_configuration.read_only_role_id
}

output "vault_read_only_role_secret_id" {
  sensitive = true
  value     = module.vault_configuration.read_only_role_secret_id
}

output "dashboard_access" {
  sensitive = false
  value     = data.terraform_remote_state.setup.outputs.dashboard_access
}

output "dashboard_token" {
  sensitive = true
  value     = data.terraform_remote_state.setup.outputs.cluster_admin_token
}

output "vault_access" {
  sensitive = false
  value     = data.terraform_remote_state.setup.outputs.vault_access
}

output "vault_admin_username" {
  sensitive = false
  value     = module.vault_configuration.admin_username
}

output "vault_admin_password" {
  sensitive = true
  value     = module.vault_configuration.admin_password
}

output "vault_read_only_username" {
  sensitive = false
  value     = module.vault_configuration.read_only_username
}

output "vault_read_only_password" {
  sensitive = true
  value     = module.vault_configuration.read_only_password
}
