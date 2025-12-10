#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_systemd_journal_upload_url"
TITLE="systemd-journal-upload.service must be configured with a remote URL"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu and rsyslog status)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'linux-base' package is not installed (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # Check if rsyslog is inactive (assuming journal-upload is used otherwise)
    if systemctl is-active rsyslog &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|rsyslog is active, journal-upload control is not applicable"
        return 0
    fi

    # Check if journal-upload.service is installed/enabled
    if ! systemctl list-unit-files | grep -q 'systemd-journal-upload.service'; then
        echo "NOTAPPL|$RULE_ID|systemd-journal-upload.service is not present."
        return 0
    fi

    local_conf_files="/etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*.conf"
    
    # Required value (from remediation block)
    var_journal_upload_url='remotelogserver'
    
    local is_ok=false

    # Check configuration files for the correct URL setting
    for conf_file in $local_conf_files; do
        [[ -e "${conf_file}" ]] || continue

        # Check if 'URL' is configured under the '[Upload]' section with the required value
        if grep -qPzos "[[:space:]]*\[Upload\]([^\n\[]*\n+)+?[[:space:]]*URL\s*=\s*${var_journal_upload_url}\s*$" "$conf_file"; then
            is_ok=true
            break
        fi
    done
    
    if $is_ok; then
        echo "OK|$RULE_ID|URL=${var_journal_upload_url} is correctly configured for systemd-journal-upload"
        return 0
    else
        echo "FAIL|$RULE_ID|URL is not correctly configured or set to '${var_journal_upload_url}' under [Upload] section"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
