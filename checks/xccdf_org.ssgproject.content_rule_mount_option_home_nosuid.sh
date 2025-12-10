#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_home_nosuid"

run() {

    # /home mount olunmayıbsa xəbərdarlıq et
    if ! mountpoint -q /home; then
        echo "WARN|$RULE_ID|/home is not a mount point"
        exit 1
    fi

    # Mount options götürülür
    opts=$(mount | grep ' /home ' | awk '{print $6}' | tr -d '()')

    # nosuid seçimi mövcuddur?
    if echo "$opts" | grep -qw nosuid; then
        echo "OK|$RULE_ID|nosuid option is set for /home"
        exit 0
    else
        echo "FAIL|$RULE_ID|nosuid option missing for /home"
        exit 1
    fi
}

run
