#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_issue"
TITLE="/etc/issue must be owned by UID 0 (root)"

run() {
    TARGET="/etc/issue"

    # Only Debian/Ubuntu systems have dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicability: only when linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (rule not applicable)"
        return 0
    fi

    # If banner file does not exist, treat as WARN (banner rules handle content/creation)
    if [ ! -e "$TARGET" ]; then
        echo "WARN|$RULE_ID|$TARGET does not exist (cannot verify owner)"
        return 0
    fi

    if ! command -v stat >/dev/null 2>&1; then
        echo "FAIL|$RULE_ID|stat command not available; cannot determine owner of $TARGET"
        return 0
    fi

    current_uid="$(stat -c '%u' "$TARGET" 2>/dev/null || echo '')"
    if [ -z "$current_uid" ]; then
        echo "FAIL|$RULE_ID|failed to obtain UID for $TARGET via stat"
        return 0
    fi

    if [ "$current_uid" = "0" ]; then
        echo "OK|$RULE_ID|$TARGET is owned by UID 0 (root)"
    else
        echo "WARN|$RULE_ID|$TARGET is owned by UID ${current_uid}, expected UID 0 (root)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
