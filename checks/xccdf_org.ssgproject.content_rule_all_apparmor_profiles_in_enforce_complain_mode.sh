#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_all_apparmor_profiles_in_enforce_complain_mode"
TITLE="All AppArmor profiles must be loaded and AppArmor active (enforce/complain modes)"

run() {

    # Not applicable inside containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    # Check AppArmor package
    if ! dpkg-query --show --showformat='${db:Status-Status}' apparmor 2>/dev/null | grep -q installed; then
        echo "WARN|$RULE_ID|AppArmor package not installed"
        return 0
    fi

    # Check aa-status availability
    if ! command -v aa-status >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|aa-status command missing"
        return 0
    fi

    # Try loading status
    if ! aa-status >/dev/null 2>&1; then
        echo "FAIL|$RULE_ID|AppArmor not active"
        return 0
    fi

    # Extract counts
    ENFORCE_COUNT=$(aa-status 2>/dev/null | awk '/profiles are in enforce mode/ {print $1}')
    COMPLAIN_COUNT=$(aa-status 2>/dev/null | awk '/profiles are in complain mode/ {print $1}')

    # Ensure numeric values
    ENFORCE_COUNT=${ENFORCE_COUNT:-0}
    COMPLAIN_COUNT=${COMPLAIN_COUNT:-0}

    if [[ $ENFORCE_COUNT -gt 0 || $COMPLAIN_COUNT -gt 0 ]]; then
        echo "OK|$RULE_ID|AppArmor active with enforce/complain profiles"
    else
        echo "WARN|$RULE_ID|AppArmor active but no profiles in enforce/complain mode"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi