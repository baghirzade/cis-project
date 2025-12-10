#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_ufw_loopback_traffic"
TITLE="Ensure ufw loopback traffic is configured"

run() {
    # Check platform applicability
    if ! command -v ufw >/dev/null 2>&1 || ! dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw package is not installed."
        return 0
    fi
    
    # Ensure ufw is active (if it's not active, these rules are irrelevant in practice)
    if [ "$(ufw status | head -n 1 | awk '{print $2}')" != "active" ]; then
        echo "NOTAPPL|$RULE_ID|ufw is not active. Loopback rules check is skipped."
        return 0
    fi

    local RETURN_CODE=0
    
    # Expected Rules in ufw status verbose:
    # 1. ALLOW in on lo
    # 2. ALLOW out on lo
    # 3. DENY in from 127.0.0.0/8
    # 4. DENY in from ::1
    
    local UFW_RULES
    UFW_RULES=$(ufw status verbose)

    # 1. Check ALLOW in on lo
    if ! grep -q -E "ALLOW\s+In\s+on\s+lo" <<< "$UFW_RULES"; then
        echo "FAIL|$RULE_ID|Missing rule: ufw allow in on lo"
        RETURN_CODE=1
    fi

    # 2. Check ALLOW out on lo
    if ! grep -q -E "ALLOW\s+Out\s+on\s+lo" <<< "$UFW_RULES"; then
        echo "FAIL|$RULE_ID|Missing rule: ufw allow out on lo"
        RETURN_CODE=1
    fi
    
    # 3. Check DENY in from 127.0.0.0/8
    # ufw status verbose usually shows 127.0.0.0/8 as 'Anywhere on lo' or a specific rule like "DENY Anywhere on lo"
    # We check the specific deny rules set by the remediation
    if ! grep -q -E "DENY\s+Anywhere\s+on\s+(?!lo)Anywhere" <<< "$UFW_RULES" || ! grep -q -E "DENY\s+Anywhere\s+from\s+127\.0\.0\.0\/8" <<< "$UFW_RULES"; then
        # This check is highly dependent on ufw output format. A more reliable check for 127.0.0.0/8 deny:
        if ! ufw status numbered | grep -q "DENY IN from 127.0.0.0/8 to any"; then
            echo "FAIL|$RULE_ID|Missing rule: ufw deny in from 127.0.0.0/8"
            RETURN_CODE=1
        fi
    fi

    # 4. Check DENY in from ::1
    if ! ufw status numbered | grep -q "DENY IN from ::1 to any"; then
        echo "FAIL|$RULE_ID|Missing rule: ufw deny in from ::1 (IPv6 loopback spoofing)"
        RETURN_CODE=1
    fi
    
    if [ "$RETURN_CODE" -eq 0 ]; then
        echo "OK|$RULE_ID|Required ufw loopback traffic rules are configured."
    fi

    return $RETURN_CODE
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
