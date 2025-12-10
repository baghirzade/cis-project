#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nosuid"

run() {

    # /dev/shm mount olunub?
    if ! mountpoint -q /dev/shm; then
        echo "WARN|$RULE_ID|/dev/shm is not a mount point"
        exit 1
    fi

    # Mövcud mount opsiyalarını götür
    opts=$(mount | grep ' /dev/shm ' | awk '{print $6}' | tr -d '()')

    # nosuid var?
    if echo "$opts" | grep -qw nosuid; then
        echo "OK|$RULE_ID|nosuid option is set for /dev/shm"
        exit 0
    else
        echo "FAIL|$RULE_ID|nosuid option missing for /dev/shm"
        exit 1
    fi
}

run
