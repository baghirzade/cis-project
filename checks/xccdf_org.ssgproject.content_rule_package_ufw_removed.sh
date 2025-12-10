#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_ufw_removed"
TITLE="Ensure the Uncomplicated Firewall (ufw) is removed"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    local var_network_filtering_service='nftables' # Assuming nftables is the required alternative
    
    # Remediation is only applicable if the required service is NOT ufw
    if [ "$var_network_filtering_service" == "ufw" ]; then
        echo "NOTAPPL|$RULE_ID|The required firewall service is set to 'ufw', so removal is not applicable."
        return 0
    fi

    # Check if 'ufw' package is installed
    if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "WARN|$RULE_ID|ufw package is installed."
        return 1
    else
        echo "OK|$RULE_ID|ufw package is not installed."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
