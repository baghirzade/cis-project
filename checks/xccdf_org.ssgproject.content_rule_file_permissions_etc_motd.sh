#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_motd"
TITLE="/etc/motd must have permissions 0644 (owner rw, group/others r)"

run() {
    TARGET="/etc/motd"

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

    # If banner file does not exist, treat as WARN (banner rules handle creation/content)
    if [ ! -e "$TARGET" ]; then
        echo "WARN|$RULE_ID|$TARGET does not exist (cannot verify permissions)"
        return 0
    fi

    if ! command -v stat >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|stat command not available; cannot determine permissions of $TARGET"
        return 0
    fi

    perms_raw="$(stat -c '%a' "$TARGET" 2>/dev/null || echo '')"
    if [ -z "$perms_raw" ]; then
        echo "WARN|$RULE_ID|failed to obtain permissions for $TARGET via stat"
        return 0
    fi

    # Normalize: allow 644 or 0644
    perms="$perms_raw"
    if [ "${#perms}" -eq 4 ]; then
        perms="${perms:1}"
    fi

    if [ "$perms" = "644" ]; then
        echo "OK|$RULE_ID|$TARGET has correct permissions 0644"
    else
        echo "WARN|$RULE_ID|$TARGET has permissions $perms_raw (expected 0644)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
