#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_pub_key"

run() {

    # Applicability
    if ! command -v dpkg >/dev/null || \
       ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|Platform not applicable"
        return 0
    fi

    # Find SSH public key files with setuid/setgid/sticky bits or group/other writes
    mapfile -t badfiles < <(
        find /etc/ssh/ -maxdepth 1 -type f -name "*.pub" \
            \( -perm /6000 -o -perm /0022 \) 2>/dev/null
    )

    # If no problematic files
    if [[ ${#badfiles[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|No SSH public key files have dangerous permissions"
        return 0
    fi

    # Build single-line output
    list=$(printf "%s " "${badfiles[@]}")

    echo "FAIL|$RULE_ID|Public key files with dangerous permissions: $list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi