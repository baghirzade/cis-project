#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_wireless_disable_interfaces"

run() {

    # Not applicable in containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    wireless_paths=$(find /sys/class/net/*/ -type d -name wireless 2>/dev/null)

    if [[ -z "$wireless_paths" ]]; then
        echo "OK|$RULE_ID|No wireless interfaces detected"
        return 0
    fi

    missing=0
    for w in $wireless_paths; do
        iface=$(basename "$(dirname "$w")")

        # Check interface is down
        state=$(cat /sys/class/net/"$iface"/operstate 2>/dev/null)
        [[ "$state" != "down" ]] && missing=1

        # Check driver is disabled in modprobe config
        driver=$(basename "$(readlink -f /sys/class/net/$iface/device/driver)")
        if ! grep -q "^install $driver /bin/false" /etc/modprobe.d/disable_wireless.conf 2>/dev/null; then
            missing=1
        fi
    done

    if [[ $missing -eq 0 ]]; then
        echo "OK|$RULE_ID|Wireless interfaces disabled and drivers blocked"
    else
        echo "WARN|$RULE_ID|Wireless interfaces not fully disabled or drivers not blocked"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

