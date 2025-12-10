#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables-persistent_installed"

echo "[*] Applying remediation for: $RULE_ID (Install iptables-persistent)"

# Check platform applicability (e.g., Debian/Ubuntu and if iptables is installed)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not available. Remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# The rule assumes the control is relevant if 'iptables' package is installed.
if dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then

    # NOTE: The variable below must reflect the actual desired network filtering service 
    # as per the overall CIS benchmark policy. Defaulting to 'nftables' per provided block.
    var_network_filtering_service='nftables'

    echo "[*] Current filtering service variable is set to: ${var_network_filtering_service}"

    if [ "$var_network_filtering_service" == "iptables" ]; then
        if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables-persistent' 2>/dev/null | grep -q '^installed$'; then
            echo "[*] Installing iptables-persistent package..."
            # Use DEBIAN_FRONTEND=noninteractive to avoid interactive prompts during installation
            if DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "iptables-persistent"; then
                echo "[+] Remediation complete: Package iptables-persistent installed."
            else
                echo "[!] ERROR: Failed to install iptables-persistent."
                exit 1
            fi
        else
            echo "[+] Package iptables-persistent is already installed. No action required."
        fi
    else
        echo "[!] Remediation condition not met: var_network_filtering_service is set to '${var_network_filtering_service}', not 'iptables'. Skipping installation."
    fi

else
    echo "[!] Remediation is not applicable, 'iptables' package is not installed."
fi
