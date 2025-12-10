#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_systemd-journal-remote_installed"
TITLE="systemd-journal-remote package should be installed when rsyslog is not active"

run() {
    # Only Debian/Ubuntu (dpkg available)
    if ! command -v dpkg-query >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg-query not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # linux-base paketi yoxdursa, bu SCAP qaydası da praktik olaraq tətbiq olunmur
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (non-standard Debian/Ubuntu environment)"
        return 0
    fi

    # Əgər rsyslog aktivdirsə, bu qayda SCAP-də də "not applicable" kimi götürülür
    if systemctl is-active rsyslog >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is active (journald remote package not required)"
        return 0
    fi

    # İndi isə yoxlayırıq ki, systemd-journal-remote paketi quraşdırılıb ya yox
    if dpkg-query --show --showformat='${db:Status-Status}' 'systemd-journal-remote' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|systemd-journal-remote package is installed (rsyslog inactive)"
    else
        echo "WARN|$RULE_ID|systemd-journal-remote package is NOT installed while rsyslog is inactive"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
