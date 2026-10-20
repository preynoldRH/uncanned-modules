# Agent instructions — Uncanned modules

This repo is **Lego for machines**. Labs (`uncanned-satellite`, `uncanned-aap`) compose these modules. Product installers live in each lab’s README.

## What this repo must prove

Reusable Terraform: network, security groups, RHEL VMs, optional sneakernet staging. After apply, boxes are empty Linux.

## Do not

- Run `satellite-installer`, `ipa-server-install`, AAP installer, or `openshift-install` from cloud-init.
- Add Satellite pulp/pgsql assumptions to `rhel_vm`. Extra disks are generic; mounts are the lab’s user-data.
- Copy this whole repo into an AAP lab. Labs consume modules; they don’t fork them.

## Verify

`terraform fmt` in this repo. Labs run `terraform validate` after they wire modules.
