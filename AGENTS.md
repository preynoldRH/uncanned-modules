# Agent instructions — Uncanned modules

This repo is **Lego for machines**. Labs (`uncanned-satellite`, `uncanned-aap`) compose these modules. Product installers live in each lab’s README.

## Ontology (read this before adding a product)

`ontology/portfolio.yaml` is the Red Hat portfolio and how products connect. `ontology/composition.yaml` is how an Uncanned lab is assembled (day 0 / 1 / 2, which git repo owns which installer).

Before you add a node, a lab, or an integration:

1. Find the product `id` and the integration `id` in the ontology.
2. Put machines in Terraform here (or compose them from a lab). Put the installer in **that lab’s README**, not in cloud-init.
3. Do not invent an integration that is not in the graph. If the customer needs a new edge, add it to `portfolio.yaml` first, then wire it.
4. A new recipe is `status: proposed` until a lab README can actually run it. Do not tell a newcomer a proposed recipe is out of the box.
5. Every recipe’s day0 is **EC2 RHEL** (`rhel_vm`), never an AWS managed service as the product host. Which RHEL major and which install model belong on the product in `portfolio.yaml` (`host`, `install_model`) — enforce them from there, do not hard-code versions only in this file.

This ontology is not an installer and not a SKU list. Growing `composition.yaml` is how you grow *your* catalog of stories. It is not a click-to-deploy catalog.

## What this repo must prove

Reusable Terraform: network, security groups, RHEL EC2 VMs, optional sneakernet staging. After apply, boxes are empty Linux.

## Do not

- Run `satellite-installer`, `ipa-server-install`, AAP installer, or `openshift-install` from cloud-init.
- Add Satellite pulp/pgsql assumptions to `rhel_vm`. Extra disks are generic; mounts are the lab’s user-data.
- Copy this whole repo into an AAP lab. Labs consume modules; they don’t fork them.
- Substitute ROSA / RDS / EKS / other managed services for product hosts. Uncanned turns on EC2 RHEL.

## Verify

`terraform fmt` in this repo. Labs run `terraform validate` after they wire modules. After ontology edits, parse the YAML (invalid YAML is a broken agent contract).
