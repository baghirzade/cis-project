#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_use_strong_kex"
TITLE="Ensure SSHD uses only strong Key Exchange (KEX) algorithms"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required KexAlgorithms (strong algorithms)
    REQUIRED_KEX='sntrup761x25519-sha512@openssh.com|curve25519-sha256|curve25519-sha256@libssh.org|ecdh-sha2-nistp256|ecdh-sha2-nistp384|ecdh-sha2-nistp521|diffie-hellman-group-exchange-sha256|diffie-hellman-group16-sha512|diffie-hellman-group18-sha512|diffie-hellman-group14-sha256'
    
    # Get the effective KexAlgorithms configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on KexAlgorithms
    CURRENT_KEX=$(sshd -T 2>/dev/null | grep -i '^kexalgorithms' | awk '{print $2}')

    if [ -z "$CURRENT_KEX" ]; then
        echo "FAIL|$RULE_ID|KexAlgorithms setting not found in active sshd configuration."
        return 1
    fi

    # Split the current KexAlgorithms list into an array
    IFS=',' read -r -a CURRENT_KEX_ARRAY <<< "$CURRENT_KEX"

    local NON_COMPLIANT_KEX=()
    
    # Check if ALL configured KEX algorithms are included in the REQUIRED_KEX list
    for kex in "${CURRENT_KEX_ARRAY[@]}"; do
        # Use simple regex check to see if the KEX is in the required list
        if ! grep -qE "^(${REQUIRED_KEX})$" <<< "$kex"; then
            NON_COMPLIANT_KEX+=("$kex")
        fi
    done
    
    # The remediation explicitly sets the list, so we must ensure that the configured list
    # does not contain any weak (unlisted) algorithms.
    
    if [ "${#NON_COMPLIANT_KEX[@]}" -gt 0 ]; then
        echo "FAIL|$RULE_ID|Non-compliant KexAlgorithms found in configuration: ${NON_COMPLIANT_KEX[*]}"
        return 1
    fi

    echo "OK|$RULE_ID|All configured SSH KEX algorithms are strong: $CURRENT_KEX"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
