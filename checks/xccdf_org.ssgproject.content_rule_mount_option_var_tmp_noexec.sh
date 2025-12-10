#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_tmp_noexec"

run() {

    # /var/tmp must be a mountpoint
    if ! mountpoint -q /var/tmp; then
        echo "WARN|$RULE_ID|/var/tmp is not a separate mount point"
        exit 1
    fi

    opts=$(mount | grep " /var/tmp " | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw noexec; then
        echo "OK|$RULE_ID|noexec is enabled on /var/tmp"
        exit 0
    else
        echo "FAIL|$RULE_ID|noexec missing on /var/tmp"
        exit 1
    fi
}

run
