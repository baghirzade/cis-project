#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_motd"

echo "[*] Applying remediation for: $RULE_ID (ensure /etc/motd is group-owned by GID 0)"

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
    echo "[!] $TARGET does not exist; cannot adjust group owner. Apply banner remediation first."
    exit 0
fi

if ! command -v stat >/dev/null 2>&1; then
    echo "[!] stat command not available; cannot determine group owner of $TARGET."
    exit 1
fi

newgroup=""
if getent group "0" >/dev/null 2>&1; then
    newgroup="0"
fi

if [[ -z "$newgroup" ]]; then
    echo "[!] GID 0 is not a defined group on the system; cannot remediate group owner for $TARGET."
    exit 1
fi

current_gid="$(stat -c '%g' "$TARGET" 2>/dev/null || echo '')"
if [ -z "$current_gid" ]; then
    echo "[!] Failed to obtain current group ID for $TARGET."
    exit 1
fi

if [ "$current_gid" = "0" ]; then
    echo "[i] $TARGET is already group-owned by GID 0 (root). Nothing to do."
    exit 0
fi

echo "[*] Changing group owner of $TARGET from GID ${current_gid} to ${newgroup}"
chgrp --no-dereference "$newgroup" "$TARGET"

echo "[+] Remediation complete: $TARGET is now group-owned by GID 0."
