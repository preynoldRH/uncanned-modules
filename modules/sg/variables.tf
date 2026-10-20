variable "name_prefix" {
  type = string
}

variable "description" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type = string
}

variable "name_tag" {
  type = string
}

variable "ingress" {
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = []
}

variable "egress" {
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = [{
    description = "all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}
