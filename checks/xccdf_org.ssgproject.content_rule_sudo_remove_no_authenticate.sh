#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_remove_no_authenticate"
TITLE="sudo configuration must not use !authenticate (no passwordless sudo via !authenticate)"

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

    # Only relevant when sudo is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|sudo is not installed (rule not applicable)"
        return 0
    fi

    if [ ! -x /usr/sbin/visudo ]; then
        echo "FAIL|$RULE_ID|/usr/sbin/visudo not found; cannot safely validate sudoers"
        return 0
    fi

    # Validate main sudoers
    if ! /usr/sbin/visudo -qcf /etc/sudoers; then
        echo "FAIL|$RULE_ID|/etc/sudoers is invalid according to visudo"
        return 0
    fi

    # Collect sudoers files (main + includes)
    files=()
    if [ -f /etc/sudoers ]; then
        files+=("/etc/sudoers")
    fi
    if [ -d /etc/sudoers.d ]; then
        while IFS= read -r -d '' f; do
            files+=("$f")
        done < <(find /etc/sudoers.d -type f -print0 2>/dev/null || true)
    fi

    if [ ${#files[@]} -eq 0 ]; then
        echo "FAIL|$RULE_ID|No sudoers files found while sudo is installed"
        return 0
    fi

    # Look for non-comment lines containing !authenticate
    if grep -P '^(?!#).*[\s]+\!authenticate.*$' "${files[@]}" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|Found active sudoers entries using !authenticate (passwordless sudo). These should be removed or commented."
    else
        echo "OK|$RULE_ID|No active sudoers entries using !authenticate were found"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
