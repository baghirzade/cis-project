#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_auth"
FILE="/var/log/auth.log"

run() {

    if [[ ! -f "$FILE" ]]; then
        echo "OK|$RULE_ID|File $FILE does not exist on this system"
        exit 0
    fi

    # Detect forbidden permission bits
    bad_perms=$(stat -c "%a" "$FILE")

    # Forbidden bits: user SUID, group write+SUID+exec, other write+exec+sticky/others
    if [[ $(stat -c "%A" "$FILE") =~ .*s.* || $(stat -c "%A" "$FILE") =~ .*.w.* || $(stat -c "%A" "$FILE") =~ .....[wx].* ]]; then
        echo "WARN|$RULE_ID|Incorrect permissions detected on $FILE (mode: $bad_perms)"
        exit 1
    fi

    echo "OK|$RULE_ID|Permissions on $FILE are correct"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
