#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-11.1"

if ! dpkg -s unattended-upgrades >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing unattended-upgrades"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y unattended-upgrades
fi

CONF="/etc/apt/apt.conf.d/20auto-upgrades"
TS="$(date +%Y%m%d-%H%M%S)"
[[ -f "$CONF" ]] && cp -p "$CONF" "${CONF}.cis.${TS}.bak"

cat > "$CONF" <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl restart unattended-upgrades.service >/dev/null 2>&1 || true
log_ok "$CONTROL_ID: unattended-upgrades enabled via $CONF"
return 0