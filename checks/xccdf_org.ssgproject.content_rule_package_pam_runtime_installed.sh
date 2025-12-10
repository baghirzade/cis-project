#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_pam_runtime_installed"
TITLE="libpam-runtime must be installed"

run() {
    # This control is generally applicable on Ubuntu
    if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|libpam-runtime package is installed"
    else
        echo "WARN|$RULE_ID|libpam-runtime package is not installed"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
