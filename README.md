# Uncanned modules

Shared **machines-only** Terraform for custom Red Hat demos. These modules turn computers on. They do not install Satellite, AAP, IdM, or OpenShift.

Repo: [preynoldRH/uncanned-modules](https://github.com/preynoldRH/uncanned-modules)

Labs that use this kit (clone next to this repo):

| Lab | What it shows |
|-----|----------------|
| [`uncanned-satellite`](https://github.com/preynoldRH/uncanned-satellite) | Dual-VPC Satellite + staging sneakernet + IdM |
| [`uncanned-aap`](https://github.com/preynoldRH/uncanned-aap) | Connected VPC + AAP controller, hub, and a client |

```bash
cd gitProjects
git clone https://github.com/preynoldRH/uncanned-modules.git
git clone https://github.com/preynoldRH/uncanned-satellite.git
git clone https://github.com/preynoldRH/uncanned-aap.git
```

## Modules

| Module | Job |
|--------|-----|
| `rhel_ami` | Latest RHEL 9 Access2 (BYOL) AMI, or an ID you pin |
| `network` | Connected VPC (internet). Optional second VPC with no IGW, plus peering |
| `sg` | Security group from a list of rules |
| `rhel_vm` | One RHEL EC2, optional extra disks, hostname/user-data you pass in |
| `staging` | NFS + HTTP “USB stick” VM (generic sneakernet, not Satellite-specific) |

## Use from a lab

```hcl
module "network" {
  source = "../../uncanned-modules/modules/network"

  name_prefix       = "aap"
  availability_zone = var.availability_zone
  enable_airgap     = false
}
```

Path assumes:

```
gitProjects/
  uncanned-modules/     # this repo
  uncanned-satellite/
  uncanned-aap/
```

To fetch a revision without a sibling clone, pin a ref:

```hcl
module "network" {
  source = "git::https://github.com/preynoldRH/uncanned-modules.git//modules/network?ref=main"
}
```

Pin `ref` to a tag in real use. Do not use git submodules.

## Rules

- No product installers in these modules.
- Cloud-init here is hostname, disks, NFS, firewall — not `satellite-installer` or `ipa-server-install`.
- See `AGENTS.md` if you are editing this with an AI assistant.
