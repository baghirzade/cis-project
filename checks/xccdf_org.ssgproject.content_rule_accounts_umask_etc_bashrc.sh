#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_bashrc"
TITLE="/etc/bash.bashrc must configure umask 027 for interactive shells"

run() {

    # Check if bash is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' bash 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|bash package is not installed"
        return 0
    fi

    FILE="/etc/bash.bashrc"

    if [[ ! -f "$FILE" ]]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        return 0
    fi

    # Extract active umask lines
    mapfile -t UMASK_LINES < <(grep -E '^[[:space:]]*umask[[:space:]]+[0-7]{3}' "$FILE" | sed 's/#.*//')

    if [[ ${#UMASK_LINES[@]} -eq 0 ]]; then
        echo "WARN|$RULE_ID|No active umask setting found in $FILE"
        return 0
    fi

    status=0
    for line in "${UMASK_LINES[@]}"; do
        val=$(awk '{for (i=1;i<=NF;i++) if ($i=="umask") print $(i+1)}' <<< "$line")

        if [[ "$val" != "027" ]]; then
            echo "WARN|$RULE_ID|Found umask '$val' (expected 027)"
            status=1
        fi
    done

    if [[ $status -eq 0 ]]; then
        echo "OK|$RULE_ID|umask 027 correctly configured in $FILE"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi