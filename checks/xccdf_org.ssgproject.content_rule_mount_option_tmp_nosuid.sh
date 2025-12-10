#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_tmp_nosuid"

run() {

    # /tmp mount olunubmu?
    if ! mountpoint -q /tmp; then
        echo "WARN|$RULE_ID|/tmp is not a mount point"
        exit 1
    fi

    # Mövcud mount options
    opts=$(mount | grep ' /tmp ' | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw nosuid; then
        echo "OK|$RULE_ID|nosuid option is present on /tmp"
        exit 0
    else
        echo "FAIL|$RULE_ID|nosuid option missing on /tmp"
        exit 1
    fi
}

run
