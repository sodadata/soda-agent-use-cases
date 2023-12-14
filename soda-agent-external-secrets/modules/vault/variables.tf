variable "vault_token" {
  description = "The token for connecting to Hashicorp Vault"
  type        = string
}

variable "admin_username" {
  description = "Username for the admin user"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Password for the admin user"
  type        = string
  default     = "admin"
}

variable "read_only_username" {
  description = "Username for the read-only user"
  type        = string
  default     = "soda"
}

variable "read_only_password" {
  description = "Password for the soda user"
  type        = string
  default     = "soda"
}

variable "read_only_token_display_name" {
  description = "Display name for the read-only token"
  type        = string
  default     = "read-only"
}
