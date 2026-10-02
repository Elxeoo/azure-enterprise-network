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

variable "admin_ip_range" {
  description = "admin_ip_range"
  type        = string
}