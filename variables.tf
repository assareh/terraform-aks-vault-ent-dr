variable "allowed_ip_cidrs" {
  description = "List of allowed IP ranges to restrict Kubernetes API access (include your IP address)"
  default     = ["0.0.0.0/0"]
}

variable "location" {
  description = "Azure location where the resources will be provisioned. In this example the TLS certs are hardcoded to westus2"
  default     = "West US 2"
}

variable "vault_license" {
  description = "Vault Enterprise license string"
  default     = null
}