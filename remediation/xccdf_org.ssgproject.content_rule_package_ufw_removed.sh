#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_ufw_removed"

echo "[*] Applying remediation for: $RULE_ID (Remove ufw package)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

# CAUTION: This remediation script will remove ufw
#          from the system, and may remove any packages
#          that depend on ufw. Execute this
#          remediation AFTER testing on a non-production
#          system!

var_network_filtering_service='nftables'

# Check if ufw is installed and is NOT the required firewall service
if [ "$var_network_filtering_service" != ufw ] && dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Removing ufw package..."
    
    # Use DEBIAN_FRONTEND=noninteractive to avoid prompting
    if DEBIAN_FRONTEND=noninteractive apt-get purge -y "ufw"; then
        echo "[+] Remediation complete: ufw package removed successfully."
    else
        echo "[!] ERROR: Failed to remove ufw package."
        exit 1
    fi
elif [ "$var_network_filtering_service" == ufw ]; then
    echo "[!] ufw is the required network filtering service. No action taken."
else
    echo "[+] ufw package is already removed. No action needed."
fi

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
