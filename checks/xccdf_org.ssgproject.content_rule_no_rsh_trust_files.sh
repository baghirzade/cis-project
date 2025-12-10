#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_rsh_trust_files"
TITLE="Ensure no RSH trust files (.rhosts, /etc/hosts.equiv) exist"

run() {
    # Check platform applicability: Only check if rsh-server is installed (though files should be removed regardless)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'rsh-server' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'rsh-server' package is not installed."
        # Continue checking files as they are security risks even if the server is removed.
    fi
    
    NON_COMPLIANT_COUNT=0
    
    echo "[*] Checking for /etc/hosts.equiv file..."
    if [ -f "/etc/hosts.equiv" ]; then
        echo "FAIL|$RULE_ID|Insecure RSH trust file /etc/hosts.equiv exists."
        NON_COMPLIANT_COUNT=$((NON_COMPLIANT_COUNT + 1))
    else
        echo "[+] /etc/hosts.equiv does not exist."
    fi

    # Find .rhosts in /root
    echo "[*] Checking for .rhosts files in /root..."
    RHOSTS_ROOT=$(find /root -xdev -type f -name ".rhosts" 2>/dev/null)
    if [ -n "$RHOSTS_ROOT" ]; then
        echo "FAIL|$RULE_ID|Insecure RSH trust file(s) found in /root: $RHOSTS_ROOT"
        NON_COMPLIANT_COUNT=$((NON_COMPLIANT_COUNT + 1))
    else
        echo "[+] No .rhosts files found in /root."
    fi

    # Find .rhosts in /home (maxdepth 2)
    echo "[*] Checking for .rhosts files in /home..."
    RHOSTS_HOME=$(find /home -maxdepth 2 -xdev -type f -name ".rhosts" 2>/dev/null)
    if [ -n "$RHOSTS_HOME" ]; then
        echo "FAIL|$RULE_ID|Insecure RSH trust file(s) found in user home directories: $RHOSTS_HOME"
        NON_COMPLIANT_COUNT=$((NON_COMPLIANT_COUNT + 1))
    else
        echo "[+] No .rhosts files found in /home directories."
    fi

    if [ "$NON_COMPLIANT_COUNT" -gt 0 ]; then
        return 1
    else
        echo "OK|$RULE_ID|No RSH trust files found."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
