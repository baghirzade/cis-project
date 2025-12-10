#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_nftables_enabled"
SYSTEMCTL_EXEC='/usr/bin/systemctl'
VAR_NETWORK_FILTERING_SERVICE='nftables'

echo "[*] Applying remediation for: $RULE_ID (Enable nftables service)"

# Check applicability: nftables installed AND firewalld inactive AND base platform check
if ( dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$' && ! (systemctl is-active firewalld &>/dev/null) && dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' ); then

    echo "[*] Ensuring nftables service is unmasked, started, and enabled."
    
    if [ "$VAR_NETWORK_FILTERING_SERVICE" == nftables ]; then
        # 1. Unmask the service (if it was masked)
        echo "    -> Unmasking nftables.service"
        "$SYSTEMCTL_EXEC" unmask 'nftables.service'
        
        # 2. Start the service (runtime)
        echo "    -> Starting nftables.service"
        "$SYSTEMCTL_EXEC" start 'nftables.service'
        
        # 3. Enable the service (on boot)
        echo "    -> Enabling nftables.service"
        "$SYSTEMCTL_EXEC" enable 'nftables.service'
        
        echo "[+] Remediation complete. nftables is now enabled and running."
    fi

else
    echo "[!] Remediation is not applicable or conflicting service (firewalld) is running. Nothing was done."
fi
