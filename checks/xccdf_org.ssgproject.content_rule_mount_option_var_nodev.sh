#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_nodev"

run() {

    # /var must be a dedicated filesystem
    if ! mountpoint -q /var; then
        echo "WARN|$RULE_ID|/var is not a separate mount point"
        exit 1
    fi

    opts=$(mount | grep " /var " | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw nodev; then
        echo "OK|$RULE_ID|nodev is enabled on /var"
        exit 0
    else
        echo "FAIL|$RULE_ID|nodev option missing on /var"
        exit 1
    fi
}

run
