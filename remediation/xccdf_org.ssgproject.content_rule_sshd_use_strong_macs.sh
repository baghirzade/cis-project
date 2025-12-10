#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_use_strong_macs"

echo "[*] Applying remediation for: $RULE_ID (Set strong SSHD MACs)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

sshd_strong_macs='hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256'
TARGET_FILE="/etc/ssh/sshd_config.d/00-complianceascode-hardening.conf"

echo "    -> Configuring MACs to: $sshd_strong_macs"

# Ensure the directory exists and the configuration file is present with correct permissions
mkdir -p /etc/ssh/sshd_config.d
touch "$TARGET_FILE"
chmod 0600 "$TARGET_FILE"

# 1. Remove existing MACs directives from main config and all drop-in files
LC_ALL=C sed -i "/^\s*MACs\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*MACs\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf 2>/dev/null || true

# 2. Ensure TARGET_FILE is clean and ends with a newline
LC_ALL=C sed -i "/^\s*MACs\s\+/Id" "$TARGET_FILE" || true
sed -i -e '$a\' "$TARGET_FILE" || true # ensure file has newline at the end

# 3. Insert the strong MACs setting at the beginning of the file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
printf '%s\n' "MACs $sshd_strong_macs" > "$TARGET_FILE"
cat "$TARGET_FILE.bak" >> "$TARGET_FILE"
rm "$TARGET_FILE.bak"

echo "[+] Remediation complete. MACs configured. SSH service may need restart."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
