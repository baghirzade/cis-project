#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_freevxfs_disabled"
FILE="/etc/modprobe.d/freevxfs.conf"

run() {

    # modul yüklənibsə — FAIL
    if lsmod | grep -q '^freevxfs'; then
        echo "WARN|$RULE_ID|freevxfs module is loaded"
        exit 1
    fi

    # install qaydası
    if ! grep -Eq '^install freevxfs /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|freevxfs install rule missing"
        exit 1
    fi

    # blacklist
    if ! grep -Eq '^blacklist freevxfs$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|freevxfs blacklist missing"
        exit 1
    fi

    echo "OK|$RULE_ID|freevxfs properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
