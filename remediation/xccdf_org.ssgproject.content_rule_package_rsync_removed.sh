#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_rsync_removed"

echo "[*] Applying remediation for: $RULE_ID (Remove rsync package)"

# Check if dpkg command exists and if the package is installed
if command -v dpkg &> /dev/null; then
    PACKAGE_NAME="rsync"
    
    if dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "    -> Package $PACKAGE_NAME is installed. Removing it now."
        
        # CAUTION: This remediation script will remove rsync
        # from the system, and may remove any packages
        # that depend on rsync.
        
        # Use DEBIAN_FRONTEND=noninteractive to avoid prompts during removal
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y "$PACKAGE_NAME"
        
        echo "[+] Remediation complete. Package $PACKAGE_NAME removed."
    else
        echo "    -> Package $PACKAGE_NAME is not installed. No action required."
    fi
else
    >&2 echo 'Remediation is not applicable, dpkg command not found.'
fi
