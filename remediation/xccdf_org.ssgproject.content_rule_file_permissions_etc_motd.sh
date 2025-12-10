#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_motd"

echo "[*] Applying remediation for: $RULE_ID (set secure permissions on /etc/motd)"

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
    echo "[!] $TARGET does not exist; cannot adjust permissions. Apply banner remediation first."
    exit 0
fi

if ! command -v chmod >/dev/null 2>&1; then
    echo "[!] chmod command not available; cannot remediate permissions on $TARGET."
    exit 1
fi

current_perms="$(stat -c '%a' "$TARGET" 2>/dev/null || echo 'unknown')"
echo "[*] Current permissions on $TARGET: $current_perms"
echo "[*] Setting permissions on $TARGET to 0644 (owner rw, group/others r)"

chmod 0644 "$TARGET"

new_perms="$(stat -c '%a' "$TARGET" 2>/dev/null || echo 'unknown')"
echo "[+] Remediation complete: permissions on $TARGET are now $new_perms"
