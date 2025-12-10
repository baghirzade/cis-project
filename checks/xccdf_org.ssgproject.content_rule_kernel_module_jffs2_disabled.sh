#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_jffs2_disabled"
FILE="/etc/modprobe.d/jffs2.conf"

run() {

    # Modul yüklənibsə — FAIL
    if lsmod | grep -q '^jffs2'; then
        echo "WARN|$RULE_ID|jffs2 kernel module is loaded"
        exit 1
    fi

    # install qaydası
    if ! grep -Eq '^install jffs2 /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|install rule missing for jffs2"
        exit 1
    fi

    # blacklist qaydası
    if ! grep -Eq '^blacklist jffs2$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|blacklist missing for jffs2"
        exit 1
    fi

    echo "OK|$RULE_ID|jffs2 module properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
