output "private_ip" {
  value = module.vm.private_ip
}

output "public_ip" {
  value = module.vm.public_ip
}

output "security_group_id" {
  value = module.sg.id
}

output "instance_id" {
  value = module.vm.id
}
