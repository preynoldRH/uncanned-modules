# Recipe: `satellite-plus-aap`

Connected Satellite SOE + AAP automation. Two labs, one story. Do not merge installers.

Diagram: [`soe-idm-satellite-aap.html`](./soe-idm-satellite-aap.html)

| Layer | Where |
|-------|--------|
| Day 0 machines | `uncanned-satellite` (connected) + `uncanned-aap` |
| Day 1 installers | each lab’s `README.md` |
| Day 1 scripting gotchas | [`day1-scripting.md`](./day1-scripting.md) (RHSM key, hammer, AAP user/SGs/8444) |
| Day 2 wiring | this document |
| Day 2 scripting gotchas | [`day2-scripting.md`](./day2-scripting.md) (register, AAP license, APD/product-demos, inventory) |

## Order of operations

1. **Connected SOE** — `uncanned-satellite` with `enable_airgap = false` (default). Follow that README through IdM, Satellite, LDAP (`soeuser`), content view, and register at least one connected workload.
2. **AAP hub** — `uncanned-aap`. Follow that README through containerized controller + private hub. You can skip the AAP-only workload; the SOE workloads are the inventory.
3. **Wire** — steps below. Read IPs from each lab’s `outputs.json`. Never invent them.

Keep product versions in the lab READMEs. Terraform only turns computers on.

A workspace-local Day 1 runner (activation key + manifest zip + AAP bundle) is fine for demos and usually **not** committed. Before scripting installs — or after a clean clone with no local runner — read [`day1-scripting.md`](./day1-scripting.md) so SG ports, hammer flags, and the `aap` install user are not rediscovered the hard way.

## Network note

Each lab creates its **own** connected VPC. Day-2 uses **public** HTTPS/SSH from `outputs.json` so you do not need peering for a first demo.

If you later want private LDAP (`aap-binds-idm`) or private inventory, give AAP a non-overlapping CIDR (for example `vpc_cidr = "10.3.0.0/16"`) and peer the VPCs — that is optional polish, not required for this recipe.

## Day 2 — inventory from Satellite

Goal: hosts Satellite knows become AAP inventory (`aap-inventory-from-satellite`).

On the controller (after AAP is up), use the Satellite inventory source (UI or API — names move by AAP version):

1. **Credentials** — Satellite credential pointing at  
   `https://<primary_satellite_public_ip>` from `uncanned-satellite/outputs.json`, org from `satellite_org`, user that can read hosts (admin for the lab, or `soeuser` once LDAP roles allow it). Trust the Satellite TLS cert the same way you do in a browser, or use the lab’s insecure-demo option if your AAP build exposes one.
2. **Inventory** — empty inventory, e.g. `SOE-from-Satellite`.
3. **Inventory source** — Satellite / Foreman plugin (or “Red Hat Satellite” source). Sync group by host collection / lifecycle environment if your version supports it.
4. **Sync** — run sync. Confirm the registered connected workload(s) appear. Prefer private hostnames Satellite knows; for SSH from a separate AAP VPC, override the ansible host with the workload **public** IP from `connected_workloads` in Satellite’s `outputs.json` (host variable / limit) so jobs still reach the box.

Anti-pattern: a static INI of public IPs that die after stop/start. Refresh `outputs.json` after stop/start if you must use public SSH targets.

## Day 2 — machine credential and patch job

Goal: patch a registered host using content the CV already has (`aap-jobs-patch-via-satellite`).

1. **Machine credential** — SSH to the workloads as `ec2-user` with the Satellite lab key (`satellite-demo-key.pem`). Import that private key into AAP; do not commit it.
2. **Project** — a small playbook repo (or manual job template) that runs something like:

   ```yaml
   - hosts: all
     become: true
     tasks:
       - name: Apply updates from Satellite-managed repos
         ansible.builtin.dnf:
           name: "*"
           state: latest
           update_cache: true
   ```

3. **Job template** — inventory = `SOE-from-Satellite`, credential = the SSH key, limit = one registered host. Run it. Show `dnf` / Satellite CV, not a random CDN mirror.
4. **Hub (optional same meeting)** — point the execution environment or collections at the private hub from `uncanned-aap` (`aap-pulls-from-private-hub`). Install path stays in the AAP README.

## Day 2 — provisioning callback (optional)

Goal: a freshly provisioned host runs a playbook without someone clicking Run (`aap-provision-callback-satellite`).

Only after inventory sync works. In Satellite, configure the provisioning callback / remote execution Ansible tip to hit the AAP controller job template URL. Pin the callback details to the AAP version you installed — do not bake them into Terraform.

## What not to do

- Do not put `satellite-installer` or the AAP installer in cloud-init or a shared `scripts/` folder.
- Do not start from the disconnected twin unless the meeting is air-gap automation.
- Do not fork Satellite to delete AAP half of a mega-repo. Two labs + this wiring doc.
- Do not expect IdM users to appear in AAP until you add LDAP there (`aap-binds-idm`) — optional; Satellite LDAP alone is enough for the SOE half of the story.
- Do not assume hub HTTPS is on 443 for containerized AAP — check **8444** and the Day 0 SGs (`day1-scripting.md`).

## Verify you have the recipe

```text
uncanned-satellite/terraform.tfvars   → enable_airgap = false
uncanned-satellite/outputs.json       → primary_satellite_*, connected_workloads, idm_*
uncanned-aap/outputs.json             → controller_*, hub_*
```

Live path: register a workload on Satellite → sync inventory into AAP → run the patch job → show the same CV the host is bound to.
