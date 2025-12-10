#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_hfsplus_disabled"
FILE="/etc/modprobe.d/hfsplus.conf"

run() {

    # Modul yüklənibsə — FAIL
    if lsmod | grep -q '^hfsplus'; then
        echo "WARN|$RULE_ID|hfsplus kernel module is loaded"
        exit 1
    fi

    # install qaydası
    if ! grep -Eq '^install hfsplus /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|install rule missing for hfsplus"
        exit 1
    fi

    # blacklist qaydası
    if ! grep -Eq '^blacklist hfsplus$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|blacklist missing for hfsplus"
        exit 1
    fi

    echo "OK|$RULE_ID|hfsplus module properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
