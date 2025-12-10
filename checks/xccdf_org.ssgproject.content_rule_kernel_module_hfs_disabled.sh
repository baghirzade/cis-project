#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_hfs_disabled"
FILE="/etc/modprobe.d/hfs.conf"

run() {

    # Modul yüklənibsə → FAIL
    if lsmod | grep -q '^hfs'; then
        echo "WARN|$RULE_ID|hfs kernel module is loaded"
        exit 1
    fi

    # install qaydası yoxlanır
    if ! grep -Eq '^install hfs /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|install rule missing for hfs"
        exit 1
    fi

    # blacklist qaydası yoxlanır
    if ! grep -Eq '^blacklist hfs$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|blacklist missing for hfs"
        exit 1
    fi

    echo "OK|$RULE_ID|hfs module properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
