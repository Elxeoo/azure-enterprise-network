variable "location" {
  description = "location"
  type        = string
  default     = "swedencentral"
}

variable "hub_address_space" {
  description = "hub_address_space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_address_space" {
  description = "spoke_address_space"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "storage_account_name" {
  description = "storage_account_name"
  type        = string
  default     = "stenterprisecan01"
}