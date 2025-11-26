#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-14.1"

if ! dpkg -s fail2ban >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing fail2ban"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y fail2ban
fi

JAIL_LOCAL="/etc/fail2ban/jail.d/cis-sshd.local"
mkdir -p /etc/fail2ban/jail.d

cat > "$JAIL_LOCAL" <<'EOF'
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = systemd
maxretry = 5
findtime = 600
bantime  = 900
EOF

systemctl enable fail2ban >/dev/null 2>&1 || true
systemctl restart fail2ban >/dev/null 2>&1 || true

log_ok "$CONTROL_ID: fail2ban installed & sshd jail enabled via $JAIL_LOCAL"
return 0