#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_backup_etc_group"

echo "[*] Applying remediation for: $RULE_ID (Configure /etc/group- permissions)"

TARGET_FILE="/etc/group-"

# Check if the file exists before proceeding
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] Remediation not applicable: Target file $TARGET_FILE does not exist. Nothing was done."
    exit 0
fi

# The remediation command: chmod u-xs,g-xws,o-xwt /etc/group-
# This removes:
# u: SUID (s), Execute (x)
# g: SGID (s), Write (w), Execute (x)
# o: Sticky (t), Write (w), Execute (x)

echo "    -> Removing unauthorized special and execute permissions: u-xs,g-xws,o-xwt"
if chmod u-xs,g-xws,o-xwt "$TARGET_FILE"; then
    echo "    -> Current permissions: $(stat -c "%a" "$TARGET_FILE")"
    echo "[+] Remediation complete: Permissions on $TARGET_FILE hardened."
else
    echo "[!] ERROR: Failed to apply chmod to $TARGET_FILE."
    exit 1
fi

# NOTE: The default standard permission for this file should be 644.
# If the file had 777 before this fix, it will still have read/write/execute set for owner/group/other after only this fix.
# We trust that other subsequent rules will fix the standard 644/000 permissions. This rule specifically handles special bits.

