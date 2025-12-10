#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_nodev"

run() {

    if ! mountpoint -q /var/log; then
        echo "WARN|$RULE_ID|/var/log is not a separate mount point"
        exit 1
    fi

    opts=$(mount | grep " /var/log " | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw nodev; then
        echo "OK|$RULE_ID|nodev is enabled on /var/log"
        exit 0
    else
        echo "FAIL|$RULE_ID|nodev option missing on /var/log"
        exit 1
    fi
}

run
