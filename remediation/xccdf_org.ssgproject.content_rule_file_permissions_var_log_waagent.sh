#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_waagent"
PATTERN_REGEX='.*waagent\.log([^/]+)?$'

echo "[*] Applying remediation for: $RULE_ID"

files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex "$PATTERN_REGEX")

if [[ -z "$files" ]]; then
    echo "[*] No waagent.log files found, nothing to remediate"
    exit 0
fi

for f in $files; do
    chmod u-xs,g-xws,o-xwt "$f"
    echo "[+] Fixed permissions on: $f"
done

echo "[+] Remediation complete for: $RULE_ID"
