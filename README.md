# Uncanned modules

Shared **machines-only** Terraform for custom Red Hat demos. These modules turn computers on. They do not install Satellite, AAP, IdM, or OpenShift.

## If you are new here

This is not the catalog. It is a kit. You still need a blank AWS Open Environment, RHEL 9 Access2 AMIs, Red Hat entitlements, and the product installer for the **version** you want to show.

1. Clone the three repos **next to each other** (see below).
2. Open the lab for a **runnable** recipe — today that is `satellite-soe` (`uncanned-satellite`) or `aap-hub` (`uncanned-aap`). Check `ontology/composition.yaml` for `status: runnable`.
3. Copy that lab’s `terraform.tfvars.example`, make an SSH key, `terraform apply`, then install from **that lab’s README**. After apply the boxes are empty on purpose.
4. A recipe with `status: proposed` is a catalog card only. Adding YAML does not create Terraform or an installer.

Give the assistant the lab folder plus this repo (the ontology lives here). `AGENTS.md` in each repo is how it should change the files.

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

## Ontology

`ontology/` is the Red Hat portfolio graph for AI assistants that build Uncanned labs: products, integrations, and which git repo owns the installer. Humans still install from each lab’s README. Terraform still only turns computers on.

## Rules

- No product installers in these modules.
- Cloud-init here is hostname, disks, NFS, firewall — not `satellite-installer` or `ipa-server-install`.
- See `AGENTS.md` if you are editing this with an AI assistant.
