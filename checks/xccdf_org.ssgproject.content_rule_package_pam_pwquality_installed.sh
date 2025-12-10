#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_pam_pwquality_installed"
TITLE="libpam-pwquality must be installed when libpam-runtime is present"

run() {
    # Applicability: only if libpam-runtime is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|libpam-runtime is not installed (control not applicable)"
        return 0
    fi

    if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-pwquality' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|libpam-pwquality package is installed"
    else
        echo "WARN|$RULE_ID|libpam-pwquality package is not installed while libpam-runtime is present"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
