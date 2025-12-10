#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_xinetd_removed"

echo "[*] Applying remediation for: $RULE_ID (Remove xinetd package)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

# Check if dpkg command exists and if the package is installed
if command -v dpkg &> /dev/null; then
    PACKAGE_NAME="xinetd"
    
    if dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "    -> Package $PACKAGE_NAME is installed. Removing it now."
        
        # CAUTION: This remediation script will remove xinetd
        # from the system, and may remove any packages
        # that depend on xinetd.
        
        # Use DEBIAN_FRONTEND=noninteractive to avoid prompts during removal
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y "$PACKAGE_NAME"
        
        echo "[+] Remediation complete. Package $PACKAGE_NAME removed."
    else
        echo "    -> Package $PACKAGE_NAME is not installed. No action required."
    fi
else
    >&2 echo 'Remediation is not applicable, dpkg command not found.'
fi

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
