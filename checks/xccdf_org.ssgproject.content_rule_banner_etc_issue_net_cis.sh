#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_banner_etc_issue_net_cis"
TITLE="/etc/issue.net must contain the CIS-compliant remote login banner"

run() {
    BANNER_FILE="/etc/issue.net"
    CIS_BANNER_TEXT='Authorized users only. All activity may be monitored and reported.'

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

    if [ ! -f "$BANNER_FILE" ]; then
        echo "WARN|$RULE_ID|$BANNER_FILE does not exist"
        return 0
    fi

    if [ ! -s "$BANNER_FILE" ]; then
        echo "WARN|$RULE_ID|$BANNER_FILE exists but is empty"
        return 0
    fi

    # Read file content, trim trailing blank lines
    file_content="$(sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}' "$BANNER_FILE")"

    if [ "$file_content" = "$CIS_BANNER_TEXT" ]; then
        echo "OK|$RULE_ID|/etc/issue.net contains the CIS-compliant banner text"
    else
        echo "WARN|$RULE_ID|/etc/issue.net banner does not match the CIS-required text"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
