#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_tmp_nosuid"

run() {

    # /var/tmp must be a mounted filesystem
    if ! mountpoint -q /var/tmp; then
        echo "WARN|$RULE_ID|/var/tmp is not a separate mount point"
        exit 1
    fi

    opts=$(mount | grep " /var/tmp " | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw nosuid; then
        echo "OK|$RULE_ID|nosuid is enabled on /var/tmp"
        exit 0
    else
        echo "FAIL|$RULE_ID|nosuid missing on /var/tmp"
        exit 1
    fi
}

run
