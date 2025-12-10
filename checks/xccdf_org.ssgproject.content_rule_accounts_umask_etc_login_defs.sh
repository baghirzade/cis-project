#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_login_defs"
TITLE="/etc/login.defs must define UMASK 027 for new accounts"

run() {

    # Check if login package is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' login 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|login package not installed"
        return 0
    fi

    FILE="/etc/login.defs"

    if [[ ! -f "$FILE" ]]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        return 0
    fi

    # Extract valid UMASK lines (ignore commented)
    mapfile -t UMASK_LINES < <(grep -Ei '^[[:space:]]*UMASK[[:space:]]+[0-7]{3}' "$FILE" | sed 's/[[:space:]]*#.*$//')

    if [[ ${#UMASK_LINES[@]} -eq 0 ]]; then
        echo "WARN|$RULE_ID|No UMASK directive found in $FILE"
        return 0
    fi

    status=0

    for line in "${UMASK_LINES[@]}"; do
        val=$(awk '{for (i=1;i<=NF;i++) if ($i=="UMASK") print $(i+1)}' <<< "$line")
        if [[ "$val" != "027" ]]; then
            echo "WARN|$RULE_ID|Found UMASK '$val' (expected 027)"
            status=1
        fi
    done

    if [[ $status -eq 0 ]]; then
        echo "OK|$RULE_ID|UMASK correctly set to 027 in $FILE"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
