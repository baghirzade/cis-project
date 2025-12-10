#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_partition_for_dev_shm"
TITLE="Separate tmpfs mount should be configured for /dev/shm"

run() {
    if ! command -v findmnt >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|findmnt command not available (cannot verify /dev/shm mount)"
        return 0
    fi

    if ! findmnt -n /dev/shm >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|/dev/shm is not present as a separate mount in the current mount table"
        return 0
    fi

    if [ -f /etc/fstab ]; then
        if grep -Eq '^[[:space:]]*tmpfs[[:space:]]+/dev/shm[[:space:]]' /etc/fstab; then
            echo "OK|$RULE_ID|/dev/shm has a separate tmpfs entry in /etc/fstab"
        else
            echo "WARN|$RULE_ID|/dev/shm is mounted but has no tmpfs entry in /etc/fstab (not persistent)"
        fi
    else
        echo "WARN|$RULE_ID|/etc/fstab not found; cannot verify persistent configuration for /dev/shm"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
