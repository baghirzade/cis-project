#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_custom_logfile"
TITLE="sudo must log to a custom logfile (/var/log/sudo.log)"

run() {
    LOGFILE="/var/log/sudo.log"

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

    # Collect sudoers files to inspect
    files=("/etc/sudoers")
    if [ -d /etc/sudoers.d ]; then
        while IFS= read -r -d '' f; do
            files+=("$f")
        done < <(find /etc/sudoers.d -type f -name '*.conf' -print0 2>/dev/null || true)
    fi

    # Any Defaults with logfile?
    if ! grep -P '^[\s]*Defaults\b[^\n]*\blogfile\s*=' "${files[@]}" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|sudoers does not configure the logfile option (Defaults logfile=...)"
        return 0
    fi

    # Is there a Defaults logfile pointing to the desired path?
    escaped_logfile="${LOGFILE//\//\\/}"
    if grep -P "^[\s]*Defaults\b[^\n]*\blogfile\s*=\s*\"?${escaped_logfile}\"?\b" "${files[@]}" >/dev/null 2>&1; then
        echo "OK|$RULE_ID|sudoers configures logfile as ${LOGFILE}"
    else
        echo "WARN|$RULE_ID|sudoers configures logfile, but not as ${LOGFILE}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
