#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_motd"

echo "[*] Applying remediation for: $RULE_ID (ensure /etc/motd is owned by UID 0)"

TARGET="/etc/motd"

# Only Debian/Ubuntu systems have dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicability: linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

if [ ! -e "$TARGET" ]; then
    echo "[!] $TARGET does not exist; cannot adjust owner. Apply banner remediation first."
    exit 0
fi

if ! command -v stat >/dev/null 2>&1; then
    echo "[!] stat command not available; cannot determine owner of $TARGET."
    exit 1
fi

newown=""
if id "0" >/dev/null 2>&1; then
    newown="0"
fi

if [[ -z "$newown" ]]; then
    echo "[!] UID 0 is not a defined user on the system; cannot remediate owner for $TARGET."
    exit 1
fi

current_uid="$(stat -c '%u' "$TARGET" 2>/dev/null || echo '')"
if [ -z "$current_uid" ]; then
    echo "[!] Failed to obtain current UID for $TARGET."
    exit 1
fi

if [ "$current_uid" = "0" ]; then
    echo "[i] $TARGET is already owned by UID 0 (root). Nothing to do."
    exit 0
fi

echo "[*] Changing owner of $TARGET from UID ${current_uid} to ${newown}"
chown --no-dereference "$newown" "$TARGET"

echo "[+] Remediation complete: $TARGET is now owned by UID 0."
