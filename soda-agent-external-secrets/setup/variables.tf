variable "base_port" {
  default     = 30200
  description = "This is the first port for the port forwarding"
  type        = number
}

variable "cluster_name" {
  default     = "soda-agent-external-secrets"
  description = "Name for the kind K8S cluster"
  type        = string
}

variable "soda_agent_namespace" {
  default     = "soda-agent"
  description = "Namespace in which the Soda Agent is installed"
  type        = string
}
