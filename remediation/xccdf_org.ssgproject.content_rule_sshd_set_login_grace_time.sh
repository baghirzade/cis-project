#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_login_grace_time"

echo "[*] Applying remediation for: $RULE_ID (Set SSHD LoginGraceTime to 60)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

var_sshd_set_login_grace_time='60'
TARGET_FILE="/etc/ssh/sshd_config.d/00-complianceascode-hardening.conf"

echo "    -> Configuring LoginGraceTime to: $var_sshd_set_login_grace_time seconds"

# Ensure the directory exists and the configuration file is present with correct permissions
mkdir -p /etc/ssh/sshd_config.d
touch "$TARGET_FILE"
chmod 0600 "$TARGET_FILE"

# 1. Remove existing LoginGraceTime directives from main config and all drop-in files
LC_ALL=C sed -i "/^\s*LoginGraceTime\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*LoginGraceTime\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf 2>/dev/null || true

# 2. Ensure TARGET_FILE is clean and ends with a newline
LC_ALL=C sed -i "/^\s*LoginGraceTime\s\+/Id" "$TARGET_FILE" || true
sed -i -e '$a\' "$TARGET_FILE" || true # ensure file has newline at the end

# 3. Insert the LoginGraceTime setting at the beginning of the file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
printf '%s\n' "LoginGraceTime $var_sshd_set_login_grace_time" > "$TARGET_FILE"
cat "$TARGET_FILE.bak" >> "$TARGET_FILE"
rm "$TARGET_FILE.bak"

echo "[+] Remediation complete. LoginGraceTime configured. SSH service may need restart."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
