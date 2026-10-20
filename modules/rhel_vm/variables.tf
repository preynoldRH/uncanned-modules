variable "name" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "availability_zone" {
  type = string
}

variable "root_volume_size" {
  type    = number
  default = 40
}

variable "associate_public_ip" {
  type    = bool
  default = true
}

variable "user_data" {
  type    = string
  default = ""
}

variable "extra_volumes" {
  description = "Extra EBS volumes. Mounting is the lab's user-data job."
  type = list(object({
    name        = string
    size        = number
    device_name = string
  }))
  default = []
}
