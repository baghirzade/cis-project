#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_enable_warning_banner_net"

echo "[*] Applying remediation for: $RULE_ID (Set SSHD Banner to /etc/issue.net)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

sshd_banner_value='/etc/issue.net'
TARGET_FILE="/etc/ssh/sshd_config.d/00-complianceascode-hardening.conf"

echo "    -> Configuring Banner to: $sshd_banner_value"

# Ensure the directory exists and the configuration file is present with correct permissions
mkdir -p /etc/ssh/sshd_config.d
touch "$TARGET_FILE"
chmod 0600 "$TARGET_FILE"

# 1. Remove existing Banner directives from main config and all drop-in files
LC_ALL=C sed -i "/^\s*Banner\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*Banner\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf 2>/dev/null || true

# 2. Ensure TARGET_FILE is clean and ends with a newline
LC_ALL=C sed -i "/^\s*Banner\s\+/Id" "$TARGET_FILE" || true
sed -i -e '$a\' "$TARGET_FILE" || true # ensure file has newline at the end

# 3. Insert the Banner setting at the beginning of the file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
printf '%s\n' "Banner $sshd_banner_value" > "$TARGET_FILE"
cat "$TARGET_FILE.bak" >> "$TARGET_FILE"
rm "$TARGET_FILE.bak"

echo "[+] Remediation complete. Banner configured. SSH service may need restart."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
