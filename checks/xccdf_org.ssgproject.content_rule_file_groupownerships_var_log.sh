#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log"

run() {

    # Find all files under /var/log except exclusions
    files=$(find -P /var/log/ -type f -regextype posix-extended \
        ! -group root ! -group adm \
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
        ! -regex '.*/lastlog(\.[^\/]+)?$' \
        ! -regex '.*/localmessages(.*)' \
        ! -regex '.*/secure(.*)' \
        ! -regex '.*/waagent.log(.*)' \
        -regex '.*' 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|All /var/log file group-owners are compliant"
        exit 0
    fi

    noncompliant=0

    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grp=$(stat -c %G "$f")

        if [[ "$grp" != "root" && "$grp" != "adm" ]]; then
            echo "WARN|$RULE_ID|$f has invalid group '$grp' (expected: root or adm)"
            noncompliant=1
        fi
    done <<< "$files"

    if [[ $noncompliant -eq 0 ]]; then
        echo "OK|$RULE_ID|All checked /var/log files are compliant"
    fi

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
