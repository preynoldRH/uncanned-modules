resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data != "" ? var.user_data : null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = { Name = var.name }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_ebs_volume" "extra" {
  for_each          = { for v in var.extra_volumes : v.name => v }
  availability_zone = var.availability_zone
  size              = each.value.size
  type              = "gp3"
  tags              = { Name = "${var.name}-${each.value.name}" }
}

resource "aws_volume_attachment" "extra" {
  for_each    = { for v in var.extra_volumes : v.name => v }
  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.extra[each.key].id
  instance_id = aws_instance.this.id
}
