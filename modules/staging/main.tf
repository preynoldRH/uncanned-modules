module "sg" {
  source      = "../sg"
  name_prefix = "${var.name_prefix}-staging-"
  description = "NFS/HTTP sneakernet staging VM"
  vpc_id      = var.vpc_id
  name_tag    = "${var.name_prefix}-staging-sg"

  ingress = concat(
    [for cidr in var.export_cidrs : {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [cidr]
    }],
    flatten([for cidr in var.export_cidrs : [
      { description = "NFS tcp", from_port = 2049, to_port = 2049, protocol = "tcp", cidr_blocks = [cidr] },
      { description = "NFS udp", from_port = 2049, to_port = 2049, protocol = "udp", cidr_blocks = [cidr] },
      { description = "rpcbind tcp", from_port = 111, to_port = 111, protocol = "tcp", cidr_blocks = [cidr] },
      { description = "rpcbind udp", from_port = 111, to_port = 111, protocol = "udp", cidr_blocks = [cidr] },
      { description = "HTTP staging", from_port = 8080, to_port = 8080, protocol = "tcp", cidr_blocks = [cidr] },
    ]])
  )
}

module "vm" {
  source             = "../rhel_vm"
  name               = "${var.name_prefix}-staging"
  ami                = var.ami
  instance_type      = var.instance_type
  subnet_id          = var.subnet_id
  key_name           = var.key_name
  security_group_ids = [module.sg.id]
  availability_zone  = var.availability_zone
  root_volume_size   = 40
  extra_volumes = [{
    name        = "data"
    size        = var.volume_size
    device_name = "/dev/sdf"
  }]
  user_data = templatefile("${path.module}/../../cloud-init/staging.sh.tftpl", {
    vpc1_cidr = var.export_cidrs[0]
    vpc2_cidr = length(var.export_cidrs) > 1 ? var.export_cidrs[1] : var.export_cidrs[0]
    hostname  = var.hostname
  })
}
