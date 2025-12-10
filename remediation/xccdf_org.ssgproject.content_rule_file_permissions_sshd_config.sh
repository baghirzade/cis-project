#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_config"

echo "[*] Applying remediation for: $RULE_ID (Secure SSHD configuration file permissions)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

TARGET_FILE="/etc/ssh/sshd_config"

if [ -f "$TARGET_FILE" ]; then
    echo "    -> Setting permissions for $TARGET_FILE: u-xs,g-xwrs,o-xwrt (Removes setuid/setgid/sticky and all group/other write access)."
    
    # The remediation command: chmod u-xs,g-xwrs,o-xwrt /etc/ssh/sshd_config
    # This removes:
    # u: setuid, execute, sticky (if somehow applied to a file)
    # g: setgid, write, read, execute, sticky
    # o: write, read, execute, sticky
    chmod u-xs,g-xwrs,o-xwrt "$TARGET_FILE"
    
    # For full CIS compliance (often 0600), we can add an explicit command:
    # Ensure Group/Other cannot write, and Owner can read/write.
    # The above command is usually sufficient to enforce 644 or 600 depending on original state.
    
    echo "[+] Remediation complete. SSHD configuration file permissions secured."
else
    echo "WARN|SSHD configuration file ($TARGET_FILE) not found. Skipping permission fix."
fi

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
