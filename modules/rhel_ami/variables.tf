variable "ami_id" {
  description = "Pin a RHEL 9 Access2 AMI. Empty = latest in this region."
  type        = string
  default     = ""
}
