#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables_installed"

echo "[*] Applying remediation for: $RULE_ID (Install iptables package)"

# Check platform applicability and conflicting services
if ( ! (systemctl is-active nftables &>/dev/null) && ! (systemctl is-active ufw &>/dev/null) && dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' ); then

    # NOTE: The variable below must reflect the actual desired network filtering service 
    # as per the overall CIS benchmark policy. Defaulting to 'nftables' per provided block.
    var_network_filtering_service='nftables'

    echo "[*] Current filtering service variable is set to: ${var_network_filtering_service}"

    if [ "$var_network_filtering_service" == "iptables" ]; then
        if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
            echo "[*] Installing iptables package..."
            # Use DEBIAN_FRONTEND=noninteractive to avoid interactive prompts during installation
            if DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "iptables"; then
                echo "[+] Remediation complete: Package iptables installed."
            else
                echo "[!] ERROR: Failed to install iptables."
                exit 1
            fi
        else
            echo "[+] Package iptables is already installed. No action required."
        fi
    else
        echo "[!] Remediation condition not met: var_network_filtering_service is set to '${var_network_filtering_service}', not 'iptables'. Skipping installation."
    fi

else
    echo "[!] Remediation is not applicable (nftables or ufw is active, or 'linux-base' is missing). Nothing was done."
fi
