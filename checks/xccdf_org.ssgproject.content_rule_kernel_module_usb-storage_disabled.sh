#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_usb-storage_disabled"
FILE="/etc/modprobe.d/usb-storage.conf"

run() {

    # USB-Storage modulunun yüklənməsi qadağandır – əgər yüklənibsə FAIL
    if lsmod | grep -q '^usb_storage'; then
        echo "WARN|$RULE_ID|usb-storage kernel module is loaded"
        exit 1
    fi

    # install qaydasını yoxla
    if ! grep -Eq '^install usb-storage /bin/false$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|install rule missing for usb-storage"
        exit 1
    fi

    # blacklist qaydasını yoxla
    if ! grep -Eq '^blacklist usb-storage$' "$FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|blacklist missing for usb-storage"
        exit 1
    fi

    echo "OK|$RULE_ID|usb-storage module is properly disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
