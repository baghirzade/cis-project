#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_disable_users_coredumps"

run() {

    # Effective configuration for coredumps
    FOUND=0

    # Check drop-in directory
    if [ -d /etc/security/limits.d ]; then
        if grep -qE "^\s*\*\s+hard\s+core\s+0\s*$" /etc/security/limits.d/*.conf 2>/dev/null; then
            FOUND=1
        fi
    fi

    # Check main limits.conf only if not found in drop-ins
    if [[ $FOUND -eq 0 ]] && grep -qE "^\s*\*\s+hard\s+core\s+0\s*$" /etc/security/limits.conf; then
        FOUND=1
    fi

    if [[ $FOUND -eq 1 ]]; then
        echo "OK|$RULE_ID|Core dumps disabled for all users"
        exit 0
    else
        echo "WARN|$RULE_ID|Core dumps are NOT fully disabled"
        exit 1
    fi
}

run
