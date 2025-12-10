#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_shells"

echo "[*] Applying remediation for: $RULE_ID (Configure /etc/shells permissions)"

TARGET_FILE="/etc/shells"

# Check if the file exists before proceeding
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] ERROR: Target file $TARGET_FILE does not exist. Cannot remediate."
    exit 1
fi

# The remediation command: chmod u-xs,g-xws,o-xwt /etc/shells
# This removes all setuid, setgid, sticky, and execute bits, and group/other write bits.

echo "    -> Removing unauthorized special and execute permissions: u-xs,g-xws,o-xwt"
if chmod u-xs,g-xws,o-xwt "$TARGET_FILE"; then
    echo "    -> Current permissions: $(stat -c "%a" "$TARGET_FILE")"
    echo "[+] Remediation complete: Permissions on $TARGET_FILE hardened."
else
    echo "[!] ERROR: Failed to apply chmod to $TARGET_FILE."
    exit 1
fi

