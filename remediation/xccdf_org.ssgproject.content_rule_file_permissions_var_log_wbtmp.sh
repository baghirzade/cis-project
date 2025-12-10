#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_wbtmp"
PATTERN_REGEX='.*(b|w)tmp((\.|-)[^/]+)?$'

echo "[*] Applying remediation for: \$RULE_ID"

files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex "$PATTERN_REGEX")

if [[ -z "$files" ]]; then
    echo "[*] No btmp/wtmp matching files found, nothing to fix"
    exit 0
fi

for f in $files; do
    chmod u-xs,g-xs,o-xwt "$f"
    echo "[+] Permissions corrected on: $f"
done

echo "[+] Remediation complete for: \$RULE_ID"
