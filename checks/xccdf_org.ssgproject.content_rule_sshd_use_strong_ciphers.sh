#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_use_strong_ciphers"
TITLE="Ensure SSHD uses only strong Ciphers"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required Ciphers (strong algorithms)
    REQUIRED_CIPHERS='aes128-ctr|aes192-ctr|aes256-ctr|chacha20-poly1305@openssh.com|aes256-gcm@openssh.com|aes128-gcm@openssh.com'
    
    # Get the effective Ciphers configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on Ciphers
    CURRENT_CIPHERS=$(sshd -T 2>/dev/null | grep -i '^ciphers' | awk '{print $2}')

    if [ -z "$CURRENT_CIPHERS" ]; then
        echo "FAIL|$RULE_ID|Ciphers setting not found in active sshd configuration."
        return 1
    fi

    # Split the current Ciphers list into an array
    IFS=',' read -r -a CURRENT_CIPHERS_ARRAY <<< "$CURRENT_CIPHERS"

    local NON_COMPLIANT_CIPHERS=()
    
    # Check if ALL configured Ciphers are included in the REQUIRED_CIPHERS list
    for cipher in "${CURRENT_CIPHERS_ARRAY[@]}"; do
        # Use simple regex check to see if the Cipher is in the required list
        if ! grep -qE "^(${REQUIRED_CIPHERS})$" <<< "$cipher"; then
            NON_COMPLIANT_CIPHERS+=("$cipher")
        fi
    done
    
    if [ "${#NON_COMPLIANT_CIPHERS[@]}" -gt 0 ]; then
        echo "FAIL|$RULE_ID|Non-compliant Ciphers found in configuration: ${NON_COMPLIANT_CIPHERS[*]}"
        return 1
    fi

    echo "OK|$RULE_ID|All configured SSH Ciphers are strong algorithms: $CURRENT_CIPHERS"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
