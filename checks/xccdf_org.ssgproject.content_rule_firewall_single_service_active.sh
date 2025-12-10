#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_firewall_single_service_active"
TITLE="Ensure only a single firewall service is active (firewalld, ufw, or iptables-services)"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # List of common firewall services to check
    FIREWALL_SERVICES=(
        "firewalld"
        "ufw"
        "iptables"
        "ip6tables"
    )
    
    ACTIVE_COUNT=0
    ACTIVE_SERVICES=""

    # Check the status of each firewall service
    for service in "${FIREWALL_SERVICES[@]}"; do
        # Check if the service package is installed
        if dpkg-query --show --showformat='${db:Status-Status}' "$service" 2>/dev/null | grep -q '^installed$'; then
            # Check if the service is running
            if systemctl is-active "$service" &>/dev/null; then
                ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
                ACTIVE_SERVICES="${ACTIVE_SERVICES}${service} "
            fi
        # Special handling for iptables/ip6tables-services which might use legacy service names
        elif systemctl is-active "${service}.service" &>/dev/null && [ "$service" == "iptables" ] || [ "$service" == "ip6tables" ]; then
            ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
            ACTIVE_SERVICES="${ACTIVE_SERVICES}${service} "
        fi
    done

    # Check the result
    if [ "$ACTIVE_COUNT" -eq 1 ]; then
        echo "OK|$RULE_ID|Only one firewall service is active: ${ACTIVE_SERVICES}"
        return 0
    elif [ "$ACTIVE_COUNT" -gt 1 ]; then
        echo "WARN|$RULE_ID|Multiple firewall services are active: ${ACTIVE_SERVICES} (Count: $ACTIVE_COUNT)"
        return 1
    else
        # If 0 services are active, it's typically a separate FAIL or WARN, but for this rule, we focus on > 1
        echo "WARN|$RULE_ID|Zero primary firewall services are active. This is a potential security risk, but the rule requirement (single active service) is met."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
