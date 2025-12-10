#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_localmessages"
SEARCH_DIR="/var/log"
PATTERN_REGEX='.*localmessages([^\/]+)?$'

echo "[*] Applying remediation for: $RULE_ID"

files=$(find -P "$SEARCH_DIR" -maxdepth 1 \
        -perm /u+xs,g+xws,o+xwt \
        -type f -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files require remediation."
    exit 0
fi

for f in $files; do
    echo "[*] Fixing permissions on: $f"
    chmod u-xs,g-xws,o-xwt "$f"
done

echo "[+] Remediation complete for rule: $RULE_ID"
