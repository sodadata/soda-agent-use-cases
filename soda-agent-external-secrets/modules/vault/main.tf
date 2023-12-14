resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_mount" "kvv2" {
  path        = "kv"
  type        = "kv-v2"
  description = "KV Version 2 secret engine mount"
}

resource "vault_generic_endpoint" "admin_user" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/${var.admin_username}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["write-secret"],
  "password": "${var.admin_password}"
}
EOT
}

resource "vault_generic_endpoint" "admin_token" {
  depends_on     = [vault_generic_endpoint.admin_user]
  path           = "auth/userpass/login/${var.admin_username}"
  disable_read   = true
  disable_delete = true

  data_json = <<EOT
{
  "password": "${var.admin_password}"
}
EOT
}

resource "vault_generic_endpoint" "admin_entity" {
  depends_on           = [vault_generic_endpoint.admin_token]
  disable_read         = true
  disable_delete       = true
  path                 = "identity/lookup/entity"
  ignore_absent_fields = true
  write_fields         = ["id"]

  data_json = <<EOT
{
  "alias_name": "${var.admin_username}",
  "alias_mount_accessor": "${vault_auth_backend.userpass.accessor}"
}
EOT
}

resource "vault_generic_endpoint" "read_only_user" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/${var.read_only_username}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["read-secret"],
  "password": "${var.read_only_password}"
}
EOT
}


resource "vault_generic_endpoint" "read_only_token" {
  depends_on     = [vault_generic_endpoint.read_only_user]
  path           = "auth/userpass/login/${var.read_only_username}"
  disable_read   = true
  disable_delete = true

  data_json = <<EOT
{
  "password": "${var.read_only_password}"
}
EOT
}

resource "vault_generic_endpoint" "read_only_entity" {
  depends_on           = [vault_generic_endpoint.read_only_token]
  disable_read         = true
  disable_delete       = true
  path                 = "identity/lookup/entity"
  ignore_absent_fields = true
  write_fields         = ["id"]

  data_json = <<EOT
{
  "alias_name": "${var.read_only_username}",
  "alias_mount_accessor": "${vault_auth_backend.userpass.accessor}"
}
EOT
}

resource "vault_policy" "write" {
  name = "write-secret"

  policy = <<EOT
path "kv/*" {
  capabilities = ["create","list", "read", "update", "delete"]
}

path "kv" {
  capabilities = ["read","list"]
}
EOT
}

resource "vault_policy" "read" {
  name = "read-secret"

  policy = <<EOT
path "kv/*" {
  capabilities = ["read","list"]
}

path "kv" {
  capabilities = ["read","list"]
}
EOT
}

resource "vault_token" "read_only" {
  display_name = var.read_only_token_display_name
  policies     = ["read-secret"]
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "read_only" {
  backend        = vault_auth_backend.approle.path
  role_name      = "read-only"
  token_policies = ["default", "read-secret"]
}

resource "vault_approle_auth_backend_role_secret_id" "read_only" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.read_only.role_name
}
