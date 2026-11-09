# Day 1 scripting — lessons for agents

Workspace-level install runners are **allowed** (outside the lab repos). Do **not** put installers in Terraform, cloud-init, or a committed `scripts/` toolbox inside `uncanned-*`. Pin product versions in each lab README; this file is the gotcha list so a clean clone can rebuild Day 1 correctly.

Read with: `ontology/composition.yaml`, `docs/satellite-plus-aap.md`, each lab `AGENTS.md` + `README.md`.

## Inputs a Day 1 runner needs

| Input | Source | Notes |
|-------|--------|--------|
| AWS creds / region | local `.env` (gitignored) | Open Environment account |
| `RHSM_ORG_ID` + `RHSM_ACTIVATION_KEY` | local `.env` | Prefer activation key over username/password |
| Admin passwords | lab `terraform.tfvars` → local `secrets.env`, or Vault later | Already written to `/etc/idm.env`, `/etc/satellite-demo.env`, `/etc/aap-lab.env` by cloud-init |
| Satellite manifest zip | local `manifest/` | Not in git |
| AAP containerized bundle tarball | local `bundles/` | Not in git; pin version in AAP README |
| Host IPs + SSH keys | each lab `outputs.json` + `*.pem` | **Never invent IPs** |

Open Environments often **stop** instances overnight. After start, public IPs change — `terraform apply -refresh-only` (or apply) and re-read `outputs.json` before SSH.

## RHSM registration

```bash
sudo subscription-manager register --org="$RHSM_ORG_ID" --activationkey="$RHSM_ACTIVATION_KEY"
sudo subscription-manager config --rhsm.manage_repos=1   # required on cloud AMIs (RHUI)
```

### Activation keys UI / list API on huge orgs

Internal Red Hat orgs often **504** on `GET /api/rhsm/v2/activation_keys` (and the console table). Work around:

- API version is **v2** (`/api/rhsm/v2/activation_keys`), not v1.
- Auth: offline token → access token (`client_id=rhsm-api`) per [access.redhat.com/management/api](https://access.redhat.com/management/api).
- **Create** a uniquely named key with `POST` and/or **GET by name** — do not rely on listing the whole org.
- Empty `additionalRepositories` on a new key is OK if the org’s default content access covers RHEL; Satellite Client/Utils sets may still be missing from an Employee SKU manifest.

## Satellite / IdM (connected SOE)

Order: IdM → `satellite-installer` → LDAP auth source → manifest → enable repos → sync → content view → `ak-rhel9`.

### Hammer (Satellite 6.19)

- `--output csv` is a **global** option: `hammer --output csv --username … repository list --organization …`
- Subcommand `repository list` has **no** `--enabled`. Enabling a repository-set creates the repository rows; list those and sync by id, or `product synchronize`.
- Soft-fail Satellite Client / Utils repository-sets when the manifest lacks those products (`product not found`). RHEL BaseOS + AppStream (+ Kickstart) is enough for the SOE story.
- Use the AMI’s `VERSION_ID` as `releasever` (e.g. `9.6`) when enabling RHEL repository-sets.
- Do not confuse **RHSM** activation keys (`subscription-manager register --activationkey=…`, often in local `.env`) with **Satellite** activation keys (`hammer activation-key create`, e.g. `ak-rhel9` for host registration to a CV).
- Satellite 6.19 `activation-key create`: use `--unlimited-hosts` as a bare flag (no `true`). There is **no** `--auto-attach`. Wrong flags yield `Too many arguments` and create nothing — do not swallow stderr with `2>/dev/null || true`.

### IdM

- `ipa-server-install` with `--no-reverse --no-host-dns` on AWS.
- Create `soeuser` outside `admins`; map IdM group `soe-users` → Satellite Viewer via LDAP auth source + external usergroup.

## AAP 2.7 containerized (controller + hub)

Preferred install model: **containerized** on RHEL 9 (`portfolio.yaml` → `aap.install_model`). Use the offline **bundle**; set `bundle_install=true` and `bundle_dir` to the extracted `bundle/` directory.

### Installer user and file permissions

- Create a non-root user (e.g. `aap`) with passwordless sudo and `loginctl enable-linger`.
- Run extract + `ansible-playbook … ansible.containerized_installer.install` **as that user**.
- `/home/aap` is mode `700` — `ec2-user` **cannot** `cd` there. Do not run installer steps as `ec2-user` inside `/home/aap`.
- If you stage `inventory-lab` via `/tmp`, do not leave it `600` owned by `ec2-user`. Hand off with `install -o aap -g aap` (or write it as `aap` from the start).

### Inventory / DNS

For controller + separate hub with Postgres on the controller:

- Put `controller.demo.local` and `hub.demo.local` in **/etc/hosts on both hosts** (private IPs from `outputs.json`).
- Hub **must** resolve `controller.demo.local` when `hub_pg_host=controller.demo.local` — otherwise: `could not translate host name "controller.demo.local"`.
- Seed SSH so `aap@controller` can reach `aap@hub` (copy key + `authorized_keys`).
- Lab inventory shape that works: gateway + controller + database on controller (`ansible_connection=local`); hub on hub VM over SSH; `redis_mode=standalone`; `automationmetrics_skip_install=true` unless you add a metrics host; `registry_auth=false` when using the offline bundle.

### Security groups (day0 must allow day1 traffic)

Containerized AAP opens **non-default** ports. Firewalld alone is not enough — **AWS SG** must allow VPC traffic:

| Host | Port | Why |
|------|------|-----|
| Controller | `5432/tcp` from VPC | Hub/gateway reach shared Postgres |
| Controller | `6379/tcp` from VPC | Redis |
| Hub | `8444/tcp` from VPC | Hub TLS (not 443) — gateway galaxy upstream |
| Hub | `8081/tcp` from VPC | Hub HTTP |

If gateway migrate fails with `503 … /api/galaxy/ … no healthy upstream`, check hub is listening on **8444** and controller→hub:8444 works. Classic miss: SG only opened 443.

Keep these rules in `uncanned-aap/terraform` `module.sg_controller` / `module.sg_hub` (already expected for new applies).

### Re-run behavior

Installer is largely idempotent; after fixing SG/DNS, re-run the same `ansible-playbook -i inventory-lab ansible.containerized_installer.install` as `aap`. Refresh public IPs after stop/start before SSH.

## What stays in which repo

| Concern | Repo |
|---------|------|
| SG ports, VPC, empty RHEL VMs | `uncanned-aap` / `uncanned-satellite` Terraform |
| Human installer steps | each lab `README.md` |
| Recipe wiring (inventory plugin, patch JT) | `docs/satellite-plus-aap.md` |
| This gotcha list | `docs/day1-scripting.md` (here) |
| Optional workspace runner | Outside `uncanned-*` (local only; not required to commit) |

## Anti-patterns

- Baking `satellite-installer` / AAP installer into cloud-init or Terraform.
- Assuming `hammer … --enabled` or subcommand `--output`.
- Listing all activation keys in a giant org.
- Inventing IPs; skipping `/etc/hosts` for `*.demo.local` across controller/hub.
- Running the containerized installer as `ec2-user` under `/home/aap`.
- Opening only 443 to the hub and expecting galaxy/gateway to work.
