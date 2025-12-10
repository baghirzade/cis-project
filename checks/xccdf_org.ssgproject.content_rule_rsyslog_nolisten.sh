#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_rsyslog_nolisten"
TITLE="Ensure rsyslog is not configured to listen on network interfaces"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu and rsyslog status)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'linux-base' package is not installed (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # Check if rsyslog is installed and active
    if ! systemctl is-active rsyslog &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|rsyslog is not active, control is not applicable"
        return 0
    fi

    # Regex for legacy format (e.g., $ModLoad imtcp, $InputTCPServerRun)
    legacy_regex='^\s*\$(((Input(TCP|RELP)|UDP)ServerRun)|ModLoad\s+(imtcp|imudp|imrelp))'
    
    # Regex for Rainer format (e.g., module(load="imtcp"), input(type="imudp"))
    rainer_regex='^\s*(module|input)\((load|type)="(imtcp|imudp|imrelp)".*$'

    # Search for active (uncommented) network listening configuration lines in /etc/rsyslog.conf and /etc/rsyslog.d/
    if grep -E -r -h -v '^\s*#' "${legacy_regex[@]}" /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null | grep -E -q "${legacy_regex}|${rainer_regex}"; then
        echo "FAIL|$RULE_ID|rsyslog is configured to listen on network interfaces (uncommented module load or input run directive found)."
        return 1
    fi

    echo "OK|$RULE_ID|rsyslog is not configured to listen on network interfaces (no active network input directives found)."
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
