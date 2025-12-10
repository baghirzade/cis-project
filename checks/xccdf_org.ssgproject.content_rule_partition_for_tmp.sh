#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_partition_for_tmp"
TITLE="Separate partition should be configured for /tmp"

run() {
    if ! command -v findmnt >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|findmnt command not available (cannot verify /tmp mount)"
        return 0
    fi

    if ! findmnt -n /tmp >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|/tmp is not present as a separate mount in the current mount table"
        return 0
    fi

    if [ -f /etc/fstab ]; then
        if grep -Eq '^[[:space:]]*[^#[:space:]]+[[:space:]]+/tmp[[:space:]]' /etc/fstab; then
            echo "OK|$RULE_ID|/tmp has a separate entry in /etc/fstab"
        else
            echo "WARN|$RULE_ID|/tmp is mounted but has no entry in /etc/fstab (not persistent)"
        fi
    else
        echo "WARN|$RULE_ID|/etc/fstab not found; cannot verify persistent configuration for /tmp"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
