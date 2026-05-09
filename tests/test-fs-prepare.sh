#!/usr/bin/env bash
# Integration test for files/fs-prepare.sh using a loop device (Linux only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/files/fs-prepare.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "missing $SCRIPT" >&2
  exit 1
fi

IMG="$(mktemp)"
MNT="$(mktemp -d)"
CADDY_SRC="$(mktemp)"
LOOP=""

cleanup() {
  if [[ -n "$MNT" ]] && mountpoint -q "$MNT" 2>/dev/null; then
    sudo umount "$MNT" || true
  fi
  if [[ -n "${LOOP:-}" ]]; then
    sudo losetup -d "$LOOP" || true
  fi
  rm -f "$IMG" "$CADDY_SRC"
  rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

# Minimal Caddy v2 snippet (tabs inside site block)
printf '%s\n' 'ci.example.duckdns.org {' $'\t''encode gzip' $'\t''reverse_proxy actual_server:5006' '}' >"$CADDY_SRC"

truncate -s 64M "$IMG"
LOOP="$(sudo losetup -f --show "$IMG")"

sudo DISK="$LOOP" MOUNT="$MNT" CADDY_SOURCE="$CADDY_SRC" bash "$SCRIPT"
[[ -f "$MNT/caddy/Caddyfile" ]] || {
  echo "expected Caddyfile after first run" >&2
  exit 1
}

# Idempotent second run (disk already ext4 + mounted)
sudo DISK="$LOOP" MOUNT="$MNT" CADDY_SOURCE="$CADDY_SRC" bash "$SCRIPT"
grep -q 'reverse_proxy' "$MNT/caddy/Caddyfile"

echo "test-fs-prepare: OK"
