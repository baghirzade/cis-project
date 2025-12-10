#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ntp_single_service_active"

echo "[*] Applying remediation for: $RULE_ID (Ensure only one NTP service is active)"

if command -v systemctl &> /dev/null; then

SYSTEMCTL_EXEC='/usr/bin/systemctl'
SERVICES_TO_DISABLE=("ntp.service" "chrony.service" "ntpd.service")
ACTIVE_SERVICE="systemd-timesyncd.service"

# 1. Stop, Disable and Mask conflicting NTP services
for SVC in "${SERVICES_TO_DISABLE[@]}"; do
    if "$SYSTEMCTL_EXEC" -q list-unit-files "$SVC"; then
        echo "    -> Stopping, disabling and masking conflicting service: $SVC"
        if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
            "$SYSTEMCTL_EXEC" stop "$SVC" || true
        fi
        "$SYSTEMCTL_EXEC" disable "$SVC" || true
        "$SYSTEMCTL_EXEC" mask "$SVC" || true
        "$SYSTEMCTL_EXEC" reset-failed "$SVC" || true
    else
        echo "    -> Conflicting service $SVC unit file not found. Skipping."
    fi
done

# 2. Ensure the recommended single service is enabled and started
if "$SYSTEMCTL_EXEC" -q list-unit-files "$ACTIVE_SERVICE"; then
    echo "    -> Ensuring recommended service $ACTIVE_SERVICE is enabled and running."
    "$SYSTEMCTL_EXEC" unmask "$ACTIVE_SERVICE" || true
    "$SYSTEMCTL_EXEC" enable "$ACTIVE_SERVICE" || true
    
    if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
        "$SYSTEMCTL_EXEC" start "$ACTIVE_SERVICE" || true
    fi
    echo "[+] Remediation complete. $ACTIVE_SERVICE is the only active time synchronization service."
else
    >&2 echo "WARNING: Recommended service $ACTIVE_SERVICE unit file not found. Please ensure a single time synchronization service is manually configured and running."
fi

else
    >&2 echo 'Remediation is not applicable, systemctl command not found.'
fi
