#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_cups_disabled"
TITLE="Ensure CUPS service is disabled and masked"

run() {
    # Check platform applicability (using linux-base as proxy for Debian/Ubuntu)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    SYSTEMCTL_EXEC='/usr/bin/systemctl'
    SERVICE_NAME='cups.service'
    
    if ! command -v "$SYSTEMCTL_EXEC" &> /dev/null; then
        echo "FAIL|$RULE_ID|systemctl command not found. Cannot determine service status."
        return 1
    fi
    
    # Check if the service exists before checking status (it might not be installed)
    if ! "$SYSTEMCTL_EXEC" list-unit-files --type=service | grep -q "$SERVICE_NAME"; then
        echo "OK|$RULE_ID|Service $SERVICE_NAME unit file not found (Implied compliance if cups is not installed)."
        return 0
    fi
    
    # 1. Check if the service is masked (highest level of disablement)
    IS_MASKED=$("$SYSTEMCTL_EXEC" is-enabled "$SERVICE_NAME" 2>/dev/null || echo "not-found")
    
    if [ "$IS_MASKED" = "masked" ]; then
        echo "[+] Service $SERVICE_NAME is masked (Compliant)."
    else
        echo "FAIL|$RULE_ID|Service $SERVICE_NAME is not masked (Current: $IS_MASKED). Must be 'masked'."
        return 1
    fi

    # 2. Check if the service is inactive (not running)
    IS_ACTIVE=$("$SYSTEMCTL_EXEC" is-active "$SERVICE_NAME" 2>/dev/null || echo "inactive")

    if [ "$IS_ACTIVE" = "inactive" ]; then
        echo "[+] Service $SERVICE_NAME is inactive (Compliant)."
        return 0
    else
        echo "FAIL|$RULE_ID|Service $SERVICE_NAME is running or failed (Current: $IS_ACTIVE). Must be 'inactive'."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
