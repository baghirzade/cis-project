#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_add_use_pty"
TITLE="sudo must be configured with Defaults use_pty"

run() {
    # Only Debian/Ubuntu systems have dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicability: only when linux-base is installed (same as SCAP)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (rule not applicable)"
        return 0
    fi

    # Rule only makes sense if sudo is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|sudo is not installed (rule not applicable)"
        return 0
    fi

    if [ ! -x /usr/sbin/visudo ]; then
        echo "FAIL|$RULE_ID|/usr/sbin/visudo not found; cannot safely validate /etc/sudoers"
        return 0
    fi

    # Validate sudoers syntax
    if ! /usr/sbin/visudo -qcf /etc/sudoers; then
        echo "FAIL|$RULE_ID|/etc/sudoers is invalid according to visudo"
        return 0
    fi

    # Combine sudoers and sudoers.d for search
    files=("/etc/sudoers")
    if [ -d /etc/sudoers.d ]; then
        while IFS= read -r -d '' f; do
            files+=("$f")
        done < <(find /etc/sudoers.d -type f -name '*.conf' -print0 2>/dev/null || true)
    fi

    # If there is any explicit !use_pty, treat as FAIL
    if grep -P '^[\s]*Defaults\b[^\n]*\!use_pty\b' "${files[@]}" >/dev/null 2>&1; then
        echo "FAIL|$RULE_ID|sudoers configuration explicitly disables use_pty (Defaults !use_pty)"
        return 0
    fi

    # Look for a positive Defaults use_pty (without '!' before it)
    if grep -P '^[\s]*Defaults\b[^!\n]*\buse_pty\b' "${files[@]}" >/dev/null 2>&1; then
        echo "OK|$RULE_ID|Defaults use_pty is configured in sudoers"
    else
        echo "WARN|$RULE_ID|Defaults use_pty is not configured in sudoers"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
