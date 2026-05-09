#!/usr/bin/env bash
# Validates fragments inside local.cloud_config (needs: terraform init -backend=false).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found; skip cloud-config checks" >&2
  exit 0
fi

terraform init -backend=false -input=false >/dev/null

expect_true() {
  local expr="$1"
  local out
  out="$(printf '%s' "$expr" | terraform console -var-file=tests/fixtures/ci.tfvars -input=false 2>/dev/null | tr -d '\r' | tail -n1)"
  if [[ "$out" != "true" ]]; then
    echo "expected true for: $expr (got: $out)" >&2
    exit 1
  fi
}

expect_true 'strcontains(local.cloud_config, "linuxserver/duckdns:latest")'
expect_true 'strcontains(local.cloud_config, "80:80")'
expect_true 'strcontains(local.cloud_config, "443:443")'
expect_true 'strcontains(local.cloud_config, "Restart=always")'
expect_true 'strcontains(local.cloud_config, "/usr/local/sbin/actual-gcp-fs-prepare.sh")'
expect_true 'strcontains(local.cloud_config, "encode gzip zstd")'

echo "check-cloud-config: OK"
