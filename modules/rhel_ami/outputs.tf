output "id" {
  value = var.ami_id != "" ? var.ami_id : data.aws_ami.rhel9_byol[0].id
}
