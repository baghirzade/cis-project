#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_localmessages"

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*localmessages.*')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No localmessages files found"
        return 0
    fi

    bad_found=0

    while IFS= read -r f; do
        grp=$(stat -c %G "$f")
        if [[ "$grp" == "adm" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group '$grp' is compliant"
        else
            echo "WARN|$RULE_ID|$f group '$grp' is not compliant (expected: adm or root)"
            bad_found=1
        fi
    done <<< "$files"

    return $bad_found
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

