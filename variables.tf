variable "subscription_id" {
  type        = string
  default     = null
  description = "Azure subscription ID (or set ARM_SUBSCRIPTION_ID)."
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region. Must be a Static Web Apps region (westeurope, westus2, centralus, eastus2, eastasia)."
}

variable "resource_group_name" {
  type    = string
  default = "rg-cloud-architecture-site-weu"
}

variable "static_web_app_name" {
  type    = string
  default = "swa-cloud-architecture"
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "Free or Standard. Standard is required for password protection, custom auth, and SLA."
}

variable "sku_size" {
  type    = string
  default = "Standard"
}

variable "custom_domain" {
  type        = string
  default     = ""
  description = "Optional custom domain (e.g. www.cloud-architecture.co.uk). Requires DNS validation."
}

variable "tags" {
  type = map(string)
  default = {
    project    = "cloud-architecture.co.uk"
    managed_by = "terraform"
  }
}
