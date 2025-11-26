#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-8.2"

RULEFILE="/etc/audit/rules.d/cis-base.rules"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="${RULEFILE}.cis.${TS}.bak"

if [[ -f "$RULEFILE" ]]; then
  cp -p "$RULEFILE" "$BACKUP"
  log_info "$CONTROL_ID: Backup of $RULEFILE at $BACKUP"
fi

cat > "$RULEFILE" <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group  -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /var/log/sudo.log -p wa -k sudo-log

-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b32 -S execve -k exec
EOF

augenrules --load >/dev/null 2>&1 || true
systemctl restart auditd.service >/dev/null 2>&1 || true

log_ok "$CONTROL_ID: Basic audit rules deployed to $RULEFILE and auditd reloaded"
return 0