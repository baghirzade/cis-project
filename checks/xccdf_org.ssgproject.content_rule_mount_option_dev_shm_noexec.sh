#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_noexec"

run() {

    # 1. /dev/shm mount olunubmu?
    if ! mountpoint -q /dev/shm; then
        echo "WARN|$RULE_ID|/dev/shm is not a mount point"
        exit 1
    fi

    # 2. noexec mount seçimi var?
    current_opts=$(mount | grep ' /dev/shm ' | awk '{print $6}' | tr -d '()')

    if echo "$current_opts" | grep -qw noexec; then
        echo "OK|$RULE_ID|noexec option is set for /dev/shm"
        exit 0
    else
        echo "WARN|$RULE_ID|noexec option missing for /dev/shm"
        exit 1
    fi
}

run
