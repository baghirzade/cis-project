#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_private_key"

run() {

    # Platform applicability
    if ! command -v dpkg >/dev/null || \
       ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|Platform not applicable"
        return 0
    fi

    REQUIRED_OWNER="root:root"

    mapfile -t keyfiles < <(find /etc/ssh/ -maxdepth 1 -type f -name "*_key" ! -name "*.pub")

    noncompliant=()

    for key in "${keyfiles[@]}"; do
        [[ -f "$key" ]] || continue

        owner=$(stat -c "%U:%G" "$key")
        perms=$(stat -c "%a" "$key")

        # Permissions: group+other must have 0 access
        go_perms=$(printf "%04o" "$perms" | cut -c 3-)

        # Check ownership
        if [[ "$owner" != "$REQUIRED_OWNER" ]]; then
            noncompliant+=("$key(owner=$owner)")
            continue
        fi

        # Check permissions
        if [[ "$go_perms" != "00" ]]; then
            noncompliant+=("$key(perms=$perms)")
            continue
        fi
    done

    if [[ ${#noncompliant[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|All SSH private key files are properly owned and secured"
        return 0
    fi

    # Build single-line message
    list=$(printf "%s " "${noncompliant[@]}")

    echo "WARN|$RULE_ID|Non-compliant SSH private key files: $list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
