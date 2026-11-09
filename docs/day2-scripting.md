# Day 2 scripting — satellite-plus-aap

Day 2 wires products that Day 1 already installed. Read `docs/satellite-plus-aap.md` and `docs/day1-scripting.md` first. Do **not** put these steps in Terraform.

## Live path (order)

1. Register connected workloads to Satellite with **`ak-rhel9`** (Satellite activation key, not RHSM).
2. License AAP (required before inventory / job launches).
3. Point AAP at [ansible/product-demos](https://github.com/ansible/product-demos) (APD bootstrap + linux/satellite demo setup).
4. Sync (or seed) inventory from Satellite; set `ansible_host` to workload **public** IPs when AAP and Satellite are in separate VPCs.
5. Run a patch / Satellite job from product-demos against a registered host (content from `cv-rhel9`).

## 1. Register workloads

On each connected workload (`outputs.json` → `connected_workload_ips`):

```bash
# private Satellite IP from outputs.json
sudo rpm -Uvh --force http://<sat_private>/pub/katello-ca-consumer-latest.noarch.rpm
sudo subscription-manager register --org="<satellite_org>" --activationkey="ak-rhel9" --force
sudo subscription-manager config --rhsm.manage_repos=1
sudo subscription-manager refresh
```

After register, pin the content release to match the CV (e.g. `sudo subscription-manager release --set=9.6`) so `$releasever` is not bare `9`.

Verify on Satellite: `hammer host list` shows `connected-wl-*.demo.local` bound to `Library/cv-rhel9`. Repo URLs must be `https://satellite…/pulp/content/…/cv-rhel9/…`.

## 2. AAP subscription (blocker if empty)

Controller `GET /api/controller/v2/config/` with empty `license_info` means **no license**. Without it:

- Inventory sync → `No license found!`
- Host create / job launch → `403 License is missing.`

Attach a subscription **before** Day 2 AAP work:

- UI: Settings → Subscription → Red Hat username/password **or** upload an **AAP** subscription manifest (not the Satellite manifest).
- API: `POST /api/controller/v2/config/` with JSON `{"eula_accepted": true, "manifest": "<base64 of zip>"}` (stable local name: `manifest/aap-subscription.zip`), **or** `POST …/config/subscriptions/` with portal `subscriptions_username` + `subscriptions_password`.

RHSM activation keys register the OS; they do **not** license AAP. Org SCA may show “Ignoring attach” on the host — still upload credentials/manifest into AAP.

Keep UUID zips from console.redhat.com and add stable symlinks in the workspace `manifest/` folder: `aap-subscription.zip` → AAP export, `satellite-manifest.zip` → Satellite export. Day 1/2 runners should prefer those names so `ls *.zip | head -1` does not grab the wrong product.

## 3. Ansible Product Demos (templates from GitHub)

Official install: [product-demos README](https://github.com/ansible/product-demos) → `install-apd.yml` with EE `quay.io/ansible-product-demos/apd-ee-27:latest` on AAP 2.7.

Creates org **Ansible Product Demos (APD)**, project **Ansible Product Demos** → `https://github.com/ansible/product-demos` (`main`), EE, machine credential, and setup job templates:

- `APD | Single demo setup` (survey: linux, satellite, …)
- `APD | Multi-demo setup`

Then launch Single/Multi for **`linux`** and **`satellite`** so patch/register/CV templates appear. Collections under `collections/ansible_collections/demo/` ship inside that repo ([demo tree](https://github.com/ansible/product-demos/tree/main/collections/ansible_collections/demo)).

EDA credential steps in `install-apd.yml` fail if EDA was not installed — ignore or skip EDA roles when the lab is controller+hub only. Controller project/templates can still succeed.

Set **APD Machine Credential** SSH key to the Satellite lab key (`satellite-demo-key.pem`) and user `ec2-user`.

## 4. Inventory from Satellite

1. Credential type **Red Hat Satellite 6**: URL `https://<primary_satellite_public_ip>`, admin (or soeuser), password from lab secrets.
2. Inventory e.g. `SOE-from-Satellite`.
3. Inventory source `source=satellite6`, `source_vars` at least:

```yaml
validate_certs: false
use_reports_api: false
host_filters: "name ~ connected-wl"
```

4. Sync. If AAP is licensed but SSL fails, you forgot `validate_certs: false` (lab uses Satellite’s self-signed cert).

Cross-VPC: Satellite inventory often has **private** IPs only. Compose or set host vars so `ansible_host` is the workload **public** IP from `connected_workload_ips`.

## 5. Patch / Satellite jobs

Prefer product-demos templates after linux+satellite setup (e.g. Linux patching, Satellite register/publish). Limit to one `connected-wl-*` host; show `dnf` / Satellite CV, not RHUI/CDN alone. Disable RHUI repos on the workload if the story must be Satellite-only.

## Open Environment notes

- Refresh `outputs.json` after stop/start (public IPs change).
- Re-sync Satellite inventory or rewrite `ansible_host` after IP change.
- Do not commit manifests, pems, or portal passwords.

## Verify

```text
hammer host list                     → connected-wl-* on Library/cv-rhel9
AAP config license_info              → non-empty
AAP project Ansible Product Demos    → scm github.com/ansible/product-demos
SOE-from-Satellite                   → workloads present, ansible_host = public IP
Job template (patch/satellite)       → successful against one workload
```

## Patching template note

`LINUX | Patching` defaults `report_server: reports`. Pass `report_server: <inventory_hostname>` (or add a `reports` host) or the job fails after a successful dnf upgrade when resolving `reports`.
