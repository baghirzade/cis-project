#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_limit_user_access"

echo "[*] Applying remediation for: $RULE_ID (Limit SSHD User Access)"

# Define allowed users or groups. NOTE: Customize this list for your environment!
# Example: root and an imaginary 'adminuser'
ALLOWED_USERS_LIST='root' 
TARGET_FILE="/etc/ssh/sshd_config.d/00-complianceascode-hardening.conf"

echo "    -> Configuring AllowUsers to: $ALLOWED_USERS_LIST (NOTE: Customize this list!)"

# Ensure the directory exists and the configuration file is present with correct permissions
mkdir -p /etc/ssh/sshd_config.d
touch "$TARGET_FILE"
chmod 0600 "$TARGET_FILE"

# 1. Remove existing access control directives from main config and all drop-in files
LC_ALL=C sed -i "/^\s*AllowUsers\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*AllowUsers\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf 2>/dev/null || true
# It is a good practice to clean up other conflicting directives as well, although not explicitly required here.
LC_ALL=C sed -i "/^\s*AllowGroups\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*DenyUsers\s\+/Id" "/etc/ssh/sshd_config" || true
LC_ALL=C sed -i "/^\s*DenyGroups\s\+/Id" "/etc/ssh/sshd_config" || true

# 2. Ensure TARGET_FILE is clean and ends with a newline
LC_ALL=C sed -i "/^\s*AllowUsers\s\+/Id" "$TARGET_FILE" || true
sed -i -e '$a\' "$TARGET_FILE" || true # ensure file has newline at the end

# 3. Insert the AllowUsers setting at the beginning of the hardening file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
printf '%s\n' "AllowUsers $ALLOWED_USERS_LIST" > "$TARGET_FILE"
cat "$TARGET_FILE.bak" >> "$TARGET_FILE"
rm "$TARGET_FILE.bak"

echo "[+] Remediation complete. AllowUsers configured. SSH service may need restart."

# This rule is generally applicable on all systems with SSH
