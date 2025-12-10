#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_autofs_disabled"

echo "[*] Remediating: $RULE_ID"

# autofs paketi quraşdırılıbsa və linux-base varsa yalnız o zaman tətbiq olunur
if dpkg -l autofs 2>/dev/null | grep -q '^ii' && dpkg -l linux-base 2>/dev/null | grep -q '^ii'; then

    SYSTEMCTL_EXEC='/usr/bin/systemctl'

    # Servis dayanır (sistem offline deyilsə)
    if [[ $("${SYSTEMCTL_EXEC}" is-system-running) != "offline" ]]; then
        "${SYSTEMCTL_EXEC}" stop autofs.service || true
    fi

    # Disable və mask
    "${SYSTEMCTL_EXEC}" disable autofs.service || true
    "${SYSTEMCTL_EXEC}" mask autefs.service || true

    # Socket varsa dayandır və mask et
    if "${SYSTEMCTL_EXEC}" -q list-unit-files autofs.socket; then
        if [[ $("${SYSTEMCTL_EXEC}" is-system-running) != "offline" ]]; then
            "${SYSTEMCTL_EXEC}" stop autofs.socket || true
        fi
        "${SYSTEMCTL_EXEC}" mask autofs.socket || true
    fi

    # State reset (failed → inactive)
    "${SYSTEMCTL_EXEC}" reset-failed autofs.service || true

    echo "[+] autofs service disabled and masked"

else
    echo "[*] Remediation is not applicable — package not installed"
fi

echo "[+] Remediation completed for: $RULE_ID"
