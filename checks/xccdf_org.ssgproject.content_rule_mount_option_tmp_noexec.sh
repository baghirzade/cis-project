#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_tmp_noexec"

run() {

    # /tmp mount olunmalıdır
    if ! mountpoint -q /tmp; then
        echo "WARN|$RULE_ID|/tmp is not a mount point"
        exit 1
    fi

    # Mövcud mount seçimlərini oxu
    opts=$(mount | grep ' /tmp ' | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw noexec; then
        echo "OK|$RULE_ID|noexec option is set for /tmp"
        exit 0
    else
        echo "FAIL|$RULE_ID|noexec option missing for /tmp"
        exit 1
    fi
}

run
