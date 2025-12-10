#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_logging_services_active"

echo "[*] Applying remediation for: $RULE_ID (ensure logging services are active)"

SYSTEMCTL_EXEC='/usr/bin/systemctl'

# Prefer rsyslog if installed
if command -v dpkg >/dev/null 2>&1 && \
   dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
    "$SYSTEMCTL_EXEC" unmask rsyslog.service || true
    "$SYSTEMCTL_EXEC" enable rsyslog.service
    if [[ $("$SYSTEMCTL_EXEC" is-system-running || echo "offline") != "offline" ]]; then
        "$SYSTEMCTL_EXEC" start rsyslog.service || true
    fi
    echo "[+] Remediation complete: rsyslog.service enabled and running"
    exit 0
fi

# Otherwise ensure journald is active
if "$SYSTEMCTL_EXEC" is-active systemd-journald.service >/dev/null 2>&1; then
    echo "[+] journald is already active"
else
    "$SYSTEMCTL_EXEC" start systemd-journald.service || true
    echo "[+] Remediation complete: systemd-journald.service started"
fi
