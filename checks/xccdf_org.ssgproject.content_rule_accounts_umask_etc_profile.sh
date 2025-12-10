#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_profile"
TITLE="/etc/profile and /etc/profile.d must set umask to 027"

run() {

    REQUIRED_UMASK="027"

    # If bash is not installed, NOT APPLICABLE
    if ! dpkg-query --show --showformat='${db:Status-Status}' bash 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|'bash' package not installed"
        return 0
    fi

    found_any=0
    bad=0

    # Files to inspect
    profile_files=()
    if [[ -d /etc/profile.d ]]; then
        mapfile -t profile_files < <(find /etc/profile.d/ -type f \( -name '*.sh' -o -name 'sh.local' \) 2>/dev/null)
    fi

    files=( "${profile_files[@]}" "/etc/profile" )

    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue

        # Extract active umask lines
        while IFS= read -r line; do
            found_any=1
            val=$(awk '{for(i=1;i<=NF;i++) if($i=="umask") print $(i+1)}' <<< "$line")

            if [[ "$val" != "$REQUIRED_UMASK" ]]; then
                echo "WARN|$RULE_ID|$file sets umask $val (expected $REQUIRED_UMASK)"
                bad=1
            fi
        done < <(grep -E '^[[:space:]]*umask[[:space:]]+[0-7]{3}' "$file" 2>/dev/null)
    done

    # No umask found anywhere
    if [[ $found_any -eq 0 ]]; then
        echo "WARN|$RULE_ID|No umask setting found in /etc/profile or /etc/profile.d"
        return 0
    fi

    # Some wrong values detected
    if [[ $bad -ne 0 ]]; then
        return 0
    fi

    echo "OK|$RULE_ID|All umask settings correctly set to $REQUIRED_UMASK"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
