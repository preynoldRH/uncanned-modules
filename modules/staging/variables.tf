variable "name_prefix" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "volume_size" {
  type    = number
  default = 300
}

variable "export_cidrs" {
  description = "CIDRs allowed to mount NFS / hit HTTP :8080 (usually both lab VPCs)."
  type        = list(string)
}

variable "hostname" {
  type    = string
  default = "staging.demo.local"
}
