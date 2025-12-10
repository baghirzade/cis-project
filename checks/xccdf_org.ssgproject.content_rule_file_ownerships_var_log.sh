#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log"

run() {

    files=$(find -P /var/log/ -type f -regextype posix-extended \
        ! -user root ! -user syslog \
        ! -name 'gdm' ! -name 'gdm3' \
        ! -name 'sssd' ! -name 'SSSD' \
        ! -name 'auth.log' \
        ! -name 'messages' \
        ! -name 'syslog' \
        ! -path '/var/log/apt/*' \
        ! -path '/var/log/landscape/*' \
        ! -path '/var/log/gdm/*' \
        ! -path '/var/log/gdm3/*' \
        ! -path '/var/log/sssd/*' \
        ! -path '/var/log/[bw]tmp*' \
        ! -path '/var/log/cloud-init.log*' \
        ! -regex '.*\.journal[~]?' \
        ! -regex '.*/lastlog(\.[^/]+)?$' \
        ! -regex '.*/localmessages(.*)' \
        ! -regex '.*/secure(.*)' \
        ! -regex '.*/waagent.log(.*)' \
        -regex '.*')

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|All log files have compliant ownership or are excluded"
        exit 0
    fi

    echo "WARN|$RULE_ID|Non-compliant files detected:"
    echo "$files"
    exit 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
