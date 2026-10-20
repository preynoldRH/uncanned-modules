output "connected_vpc_id" {
  value = aws_vpc.connected.id
}

output "connected_subnet_id" {
  value = aws_subnet.connected_public.id
}

output "connected_cidr" {
  value = var.connected_cidr
}

output "airgap_vpc_id" {
  value = var.enable_airgap ? aws_vpc.airgap[0].id : null
}

output "airgap_subnet_id" {
  value = var.enable_airgap ? aws_subnet.airgap_private[0].id : null
}

output "airgap_cidr" {
  value = var.enable_airgap ? var.airgap_cidr : null
}

output "enable_airgap" {
  value = var.enable_airgap
}
