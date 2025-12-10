#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_audit_nosuid"

run() {

    if ! mountpoint -q /var/log/audit; then
        echo "WARN|$RULE_ID|/var/log/audit is not a mount point"
        exit 1
    fi

    opts=$(mount | grep ' /var/log/audit ' | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw nosuid; then
        echo "OK|$RULE_ID|nosuid option is enabled on /var/log/audit"
        exit 0
    else
        echo "FAIL|$RULE_ID|nosuid option is missing on /var/log/audit"
        exit 1
    fi
}

run
