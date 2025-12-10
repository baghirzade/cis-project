#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_use_strong_macs"
TITLE="Ensure SSHD uses only strong Message Authentication Codes (MACs)"

run() {
    # Check platform applicability
    if ! command -v dpkg >/dev/null 2>&1 || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required MACs (strong algorithms)
    REQUIRED_MACS='hmac-sha2-512-etm@openssh.com|hmac-sha2-256-etm@openssh.com|hmac-sha2-512|hmac-sha2-256'
    
    # Get the effective MACs configuration from sshd config files
    # The 'sshd -T' command provides the definitive running configuration
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on MACs
    CURRENT_MACS=$(sshd -T 2>/dev/null | grep -i '^macs' | awk '{print $2}')

    if [ -z "$CURRENT_MACS" ]; then
        echo "WARN|$RULE_ID|MACs setting not found in active sshd configuration."
        return 1
    fi

    # Split the current MACs list into an array
    IFS=',' read -r -a CURRENT_MACS_ARRAY <<< "$CURRENT_MACS"

    local NON_COMPLIANT_MACS=()
    local ALL_COMPLIANT=0

    # Check if ALL configured MACs are included in the REQUIRED_MACS list
    for mac in "${CURRENT_MACS_ARRAY[@]}"; do
        # Use simple regex check to see if the MAC is in the required list
        if ! grep -qE "^(${REQUIRED_MACS})$" <<< "$mac"; then
            NON_COMPLIANT_MACS+=("$mac")
        fi
    done
    
    # We must ensure that the configured list is EXACTLY the strong list or a subset of it,
    # and preferably contains at least one of the ETM (Encrypt-then-Mac) versions if supported.
    # For a stricter check (as implied by the remediation, which sets only the strong ones):
    
    if [ "${#NON_COMPLIANT_MACS[@]}" -gt 0 ]; then
        echo "WARN|$RULE_ID|Non-compliant MACs found in configuration: ${NON_COMPLIANT_MACS[*]}"
        return 1
    fi

    # Check if at least one MAC is defined (implied by non-empty CURRENT_MACS)
    
    echo "OK|$RULE_ID|All configured SSH MACs are strong algorithms: $CURRENT_MACS"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
