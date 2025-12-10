#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_do_not_permit_user_env"

echo "[*] Applying remediation for: $RULE_ID (Disable SSHD PermitUserEnvironment)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

sshd_permit_user_env_value='no'
TARGET_FILE="/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"

echo "    -> Configuring PermitUserEnvironment to: $sshd_permit_user_env_value"

# Ensure the directory exists and the configuration file is present with correct permissions
mkdir -p /etc/ssh/sshd_config.d
touch "$TARGET_FILE"
chmod 0600 "$TARGET_FILE"

# 1. Remove existing PermitUserEnvironment directives from main config and all drop-in files
LC_ALL=C sed -i "/^\s*PermitUserEnvironment\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*PermitUserEnvironment\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf 2>/dev/null || true

# 2. Ensure TARGET_FILE is clean and ends with a newline
LC_ALL=C sed -i "/^\s*PermitUserEnvironment\s\+/Id" "$TARGET_FILE" || true
sed -i -e '$a\' "$TARGET_FILE" || true # ensure file has newline at the end

# 3. Insert the PermitUserEnvironment setting at the beginning of the file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
printf '%s\n' "PermitUserEnvironment $sshd_permit_user_env_value" > "$TARGET_FILE"
cat "$TARGET_FILE.bak" >> "$TARGET_FILE"
rm "$TARGET_FILE.bak"

echo "[+] Remediation complete. PermitUserEnvironment configured. SSH service may need restart."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
