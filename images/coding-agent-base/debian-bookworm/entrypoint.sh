#!/usr/bin/env bash
set -euo pipefail

mkdir -p /home/arron/.ssh
chmod 700 /home/arron /home/arron/.ssh
sudo mkdir -p /run/sshd
sudo ssh-keygen -A >/dev/null

if [ -f /home/arron/.ssh/authorized_keys ]; then
  chmod 600 /home/arron/.ssh/authorized_keys 2>/dev/null || true
fi

# OrbStack DNS (127.0.0.11) unreachable from shared network namespace.
# Point to sing-box gateway tun0 IP where hijack-dns intercepts DNS queries.
printf 'nameserver 172.19.0.1\noptions timeout:1 attempts:1\n' | sudo tee /etc/resolv.conf >/dev/null

# Add scripts to PATH
[ -f /data/work_dir/dev_env/scripts/setup-shell-env.sh ] && bash /data/work_dir/dev_env/scripts/setup-shell-env.sh

sudo /usr/sbin/sshd

exec "$@"
