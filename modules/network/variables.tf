variable "name_prefix" {
  type    = string
  default = "demo"
}

variable "availability_zone" {
  type = string
}

variable "connected_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "connected_subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "enable_airgap" {
  description = "Second VPC with no internet gateway, peered to the connected VPC."
  type        = bool
  default     = false
}

variable "airgap_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "airgap_subnet_cidr" {
  type    = string
  default = "10.2.1.0/24"
}
