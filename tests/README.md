# Tests

These checks catch **syntax / wiring** problems early. They do **not** replace a real deploy: a full `terraform apply` still needs a GCP project, credentials, and billing, and it exercises Docker pulls, DNS, and Let’s Encrypt on the VM.

## What runs in CI (GitHub Actions)

| Job | What it proves |
|-----|----------------|
| **terraform** | `fmt`, `validate`, and that `local.cloud_config` contains expected fragments (Caddy **:80**/**:443**, DuckDNS image, **Restart=always**, fs-prepare path). |
| **fs-prepare** | **`files/fs-prepare.sh`** passes **shellcheck** and works on a **loop-mounted** ext4 image (format once, mount, seed Caddyfile, idempotent second run). |

## Run locally

### Linux (or WSL), full checks

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
bash tests/check-cloud-config.sh
sudo bash tests/test-fs-prepare.sh
shellcheck files/fs-prepare.sh
```

### Windows (PowerShell)

Formatting and validate (no loop-device test without Linux):

```powershell
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

Use **WSL** or **GitHub Actions** on your fork for the fs-prepare integration test.

## End-to-end (your GCP project)

After `terraform apply`, use the README post-deploy steps (`docker ps`, `journalctl`, HTTPS to `actual_fqdn`). That is the only complete proof that **registry pulls**, **DuckDNS**, and **ACME** succeed in your environment.
