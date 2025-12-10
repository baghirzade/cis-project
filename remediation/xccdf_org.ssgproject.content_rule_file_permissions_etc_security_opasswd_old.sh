#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_security_opasswd_old"

echo "[*] Applying remediation for: $RULE_ID (Configure /etc/security/opasswd.old permissions)"

TARGET_FILE="/etc/security/opasswd.old"

# Check if the file exists before proceeding
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] Remediation not applicable: Target file $TARGET_FILE does not exist. Nothing was done."
    exit 0
fi

# The remediation command: chmod u-xs,g-xwrs,o-xwrt /etc/security/opasswd.old
# This removes:
# u: SUID (s), Execute (x)
# g: SGID (s), Write (w), Read (r), Execute (x)
# o: Sticky (t), Write (w), Read (r), Execute (x)
# This effectively clears all Group and Other permissions, and removes Owner SUID/Execute bits.

echo "    -> Removing unauthorized special and read/write/execute permissions for group/other: u-xs,g-xwrs,o-xwrt"
if chmod u-xs,g-xwrs,o-xwrt "$TARGET_FILE"; then
    echo "    -> Current permissions: $(stat -c "%a" "$TARGET_FILE")"
    echo "[+] Remediation complete: Permissions on $TARGET_FILE hardened."
else
    echo "[!] ERROR: Failed to apply chmod to $TARGET_FILE."
    exit 1
fi

