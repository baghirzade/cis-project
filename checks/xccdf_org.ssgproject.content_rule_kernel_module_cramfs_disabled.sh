#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_cramfs_disabled"

run() {

    FILE="/etc/modprobe.d/cramfs.conf"

    # modul yüklənibsə FAIL
    if lsmod | grep -q '^cramfs'; then
        echo "WARN|$RULE_ID|cramfs module is loaded"
        exit 1
    fi

    # install qaydası yoxlanır
    if ! grep -Eq '^install cramfs /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|cramfs install rule missing"
        exit 1
    fi

    # blacklist yoxlanır
    if ! grep -Eq '^blacklist cramfs$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|cramfs blacklist missing"
        exit 1
    fi

    echo "OK|$RULE_ID|cramfs properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
