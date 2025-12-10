#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_permissions_local_var_log"

run() {

    # Skip for containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    # Find log files with dangerous permissions
    bad_files=$( \
        find -P /var/log/ \
            -perm /u+xs,g+xws,o+xwrt \
            ! -name 'history.log*' \
            ! -name 'eipp.log.xz*' \
            ! -name '[bw]tmp' \
            ! -name '[bw]tmp.*' \
            ! -name '[bw]tmp-*' \
            ! -name 'lastlog' \
            ! -name 'lastlog.*' \
            ! -name 'cloud-init.log*' \
            ! -name 'localmessages*' \
            ! -name 'waagent.log*' \
            -type f -regextype posix-extended -regex '.*' 2>/dev/null )

    if [[ -z "$bad_files" ]]; then
        echo "OK|$RULE_ID|No log files with insecure permissions found"
    else
        echo "WARN|$RULE_ID|Found insecure log file permissions under /var/log"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

