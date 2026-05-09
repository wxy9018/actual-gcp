#!/bin/bash
# Formats (once), mounts the data disk, lays out paths, seeds Caddyfile.
# Defaults match GCE + cloud-init; override DISK/MOUNT/CADDY_SOURCE for tests.
set -euo pipefail

DISK="${DISK:-/dev/disk/by-id/google-persistent-disk-1}"
MOUNT="${MOUNT:-/mnt/disks/data}"
CADDY_SOURCE="${CADDY_SOURCE:-/tmp/Caddyfile}"

mkdir -p "$MOUNT"

FSTYPE="$(blkid -o value -s TYPE "$DISK" 2>/dev/null || true)"
if [ -z "$FSTYPE" ]; then
  mkfs.ext4 -L data -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DISK"
elif [ "$FSTYPE" != "ext4" ]; then
  echo "actual-gcp-fs-prepare: $DISK has unexpected filesystem type '$FSTYPE' (expected ext4 or empty); refusing to mount." >&2
  exit 1
else
  fsck.ext4 -tfy "$DISK" || true
fi

if ! findmnt "$MOUNT" >/dev/null 2>&1; then
  mount -t ext4 -o nodev,nosuid,nofail "$DISK" "$MOUNT"
fi

mkdir -p "$MOUNT/caddy/data" "$MOUNT/caddy/config" "$MOUNT/actual-data"

# First boot: cloud-init writes /tmp/Caddyfile. Later boots: /tmp may be empty; keep copy on disk.
if [ -f "$CADDY_SOURCE" ]; then
  cp "$CADDY_SOURCE" "$MOUNT/caddy/Caddyfile"
elif [ ! -f "$MOUNT/caddy/Caddyfile" ]; then
  echo "actual-gcp-fs-prepare: missing $CADDY_SOURCE and no $MOUNT/caddy/Caddyfile" >&2
  exit 1
fi

# Persist mount across reboots (COS: skip if testing with a non-standard MOUNT path).
if [ "$MOUNT" = "/mnt/disks/data" ]; then
  FSTAB_LINE='LABEL=data /mnt/disks/data ext4 nodev,nosuid,nofail 0 2'
  if ! grep -qs '/mnt/disks/data' /etc/fstab; then
    echo "$FSTAB_LINE" >>/etc/fstab
  fi
fi

# Bridge for Caddy/Actual (safe if Docker is not up yet — e.g. some test environments).
if [ -x /usr/bin/docker ] && /usr/bin/docker info >/dev/null 2>&1; then
  /usr/bin/docker network create custom-bridge 2>/dev/null || true
fi
