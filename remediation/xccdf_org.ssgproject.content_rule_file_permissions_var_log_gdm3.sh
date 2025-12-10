#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_gdm3"
LOG_DIR="/var/log/gdm3"
PATTERN_REGEX='.*'

echo "[*] Applying remediation for: $RULE_ID"

files=$(find -P "$LOG_DIR" -perm /u+xs,g+xs,o+xwrt -type f \
         -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files requiring remediation."
    exit 0
fi

for f in $files; do
    echo "[*] Fixing permissions on: $f"
    chmod u-xs,g-xs,o-xwrt "$f"
done

echo "[+] Remediation complete for rule: $RULE_ID"
