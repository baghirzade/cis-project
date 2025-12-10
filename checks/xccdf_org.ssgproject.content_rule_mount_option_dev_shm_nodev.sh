#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nodev"

run() {

    # 1. /dev/shm mount olunubmu?
    if ! mountpoint -q /dev/shm; then
        echo "WARN|$RULE_ID|/dev/shm is not a mount point"
        exit 1
    fi

    # 2. nodev mount seçimi aktivdir?
    current_opts=$(mount | grep ' /dev/shm ' | awk '{print $6}' | tr -d '()')

    if echo "$current_opts" | grep -qw nodev; then
        echo "OK|$RULE_ID|nodev option is set for /dev/shm"
        exit 0
    else
        echo "FAIL|$RULE_ID|nodev option missing for /dev/shm"
        exit 1
    fi
}

run
