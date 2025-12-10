#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_has_nonlocal_mta"
TITLE="System must have a non-local MTA installed"

run() {
    # Debian/Ubuntu requirement
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian platform"
        return 0
    fi

    # Check for commonly used MTAs
    MTA_PACKAGES=("postfix" "exim4" "sendmail" "nullmailer" "ssmtp" "msmtp")

    for pkg in "${MTA_PACKAGES[@]}"; do
        if dpkg-query --show --showformat='${db:Status-Status}' "$pkg" 2>/dev/null \
           | grep -q '^installed$'; then
            echo "OK|$RULE_ID|Non-local MTA installed: $pkg"
            return 0
        fi
    done

    echo "FAIL|$RULE_ID|No non-local MTA installed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
