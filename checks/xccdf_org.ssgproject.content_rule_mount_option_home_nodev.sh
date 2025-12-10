#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_home_nodev"

run() {

    # /home mount olunub?
    if ! mountpoint -q /home; then
        echo "WARN|$RULE_ID|/home is not a mount point"
        exit 1
    fi

    # Mövcud mount opsiyalarını götür
    opts=$(mount | grep ' /home ' | awk '{print $6}' | tr -d '()')

    # nodev var?
    if echo "$opts" | grep -qw nodev; then
        echo "OK|$RULE_ID|nodev option is set for /home"
        exit 0
    else
        echo "FAIL|$RULE_ID|nodev option missing for /home"
        exit 1
    fi
}

run
