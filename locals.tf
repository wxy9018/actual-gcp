locals {
  cloud_config = <<-EOT
    #cloud-config
    ${yamlencode({
  write_files = [
    {
      path        = "/etc/systemd/system/duckdns.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT1
            [Unit]
            Description=Start DuckDNS
            After=docker.service
            Wants=docker.service

            [Service]
            Restart=always
            RestartSec=30
            ExecStart=/usr/bin/docker run --rm -e SUBDOMAINS=${var.duckdns_subdomains} -e TOKEN=${var.duckdns_token} --name=duckdns linuxserver/duckdns:latest
            ExecStop=/usr/bin/docker stop duckdns
            ExecStopPost=-/usr/bin/docker rm duckdns
            EOT1
    },
    {
      path        = "/etc/systemd/system/caddy.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT2
            [Unit]
            Description=Start Caddy
            After=docker.service
            Wants=docker.service

            [Service]
            Restart=always
            RestartSec=30
            ExecStart=/usr/bin/docker run --rm --network custom-bridge -p 80:80 -p 443:443 --mount 'type=bind,source=/mnt/disks/data/caddy/Caddyfile,target=/etc/caddy/Caddyfile,readonly' --mount 'type=bind,source=/mnt/disks/data/caddy/data,target=/data' --mount 'type=bind,source=/mnt/disks/data/caddy/config,target=/config' --name=caddy caddy:alpine
            ExecStop=/usr/bin/docker stop caddy
            ExecStopPost=-/usr/bin/docker rm caddy
            EOT2
    },
    {
      path        = "/etc/systemd/system/actual.service"
      permissions = "0644"
      owner       = "root"
      content     = <<-EOT3
            [Unit]
            Description=Start Actual
            After=docker.service
            Wants=docker.service

            [Service]
            Restart=always
            RestartSec=30
            ExecStart=/usr/bin/docker run --rm --network custom-bridge -p '[::1]:5006:5006' --mount 'type=bind,source=/mnt/disks/data/actual-data,target=/data' --name=actual_server actualbudget/actual-server:latest
            ExecStop=/usr/bin/docker stop actual_server
            ExecStopPost=-/usr/bin/docker rm actual_server
            EOT3
    },
    {
      path        = "/tmp/Caddyfile"
      permissions = "0644"
      owner       = "root"
      content     = "${var.actual_fqdn} {\n${"\t"}encode gzip zstd\n${"\t"}reverse_proxy actual_server:5006\n}\n"
    },
    {
      path        = "/usr/local/sbin/actual-gcp-fs-prepare.sh"
      permissions = "0544"
      owner       = "root"
      content     = <<-EOT5
            #!/bin/bash
            set -euo pipefail

            DISK=/dev/disk/by-id/google-persistent-disk-1
            MOUNT=/mnt/disks/data

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
              mount -t ext4 -o nodev,nosuid "$DISK" "$MOUNT"
            fi

            mkdir -p "$MOUNT/caddy/data" "$MOUNT/caddy/config" "$MOUNT/actual-data"
            cp /tmp/Caddyfile "$MOUNT/caddy/Caddyfile"
            EOT5
    }
  ]

  runcmd = [
    "/usr/local/sbin/actual-gcp-fs-prepare.sh",
    "docker network create custom-bridge || true",
    "systemctl daemon-reload",
    "systemctl start caddy.service",
    "systemctl start actual.service",
    "systemctl start duckdns.service"
  ]
})}
  EOT
}
