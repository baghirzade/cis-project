#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_audit_noexec"

run() {

    if ! mountpoint -q /var/log/audit; then
        echo "WARN|$RULE_ID|/var/log/audit is not a mount point"
        exit 1
    fi

    opts=$(mount | grep ' /var/log/audit ' | awk '{print $6}' | tr -d '()')

    if echo "$opts" | grep -qw noexec; then
        echo "OK|$RULE_ID|noexec option is enabled on /var/log/audit"
        exit 0
    else
        echo "FAIL|$RULE_ID|noexec option is missing on /var/log/audit"
        exit 1
    fi
}

run
