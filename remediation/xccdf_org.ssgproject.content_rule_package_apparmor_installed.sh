#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_apparmor_installed"

echo "[*] Applying remediation for: $RULE_ID (Install AppArmor package)"

# Remediation is not applicable in container environments
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then

    # Check if dpkg command exists
    if ! command -v dpkg &> /dev/null; then
        >&2 echo 'Remediation failed: dpkg command not found.'
        exit 1
    fi
    
    PACKAGE_NAME="apparmor"
    
    if ! dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "    -> Package $PACKAGE_NAME is not installed. Installing it now."
        
        # Use DEBIAN_FRONTEND=noninteractive to avoid prompts during installation
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$PACKAGE_NAME"
        
        echo "[+] Remediation complete. Package $PACKAGE_NAME installed."
    else
        echo "    -> Package $PACKAGE_NAME is already installed. No action required."
    fi

else
    >&2 echo 'Remediation is not applicable, running in a container environment.'
fi
