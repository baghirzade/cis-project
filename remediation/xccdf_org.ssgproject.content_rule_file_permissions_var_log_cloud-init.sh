#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_cloud-init"
PATTERN_REGEX='.*cloud-init\.log([^\/]+)?$'
LOG_DIR="/var/log"

echo "[*] Applying remediation for: $RULE_ID"

files=$(find -P "$LOG_DIR" -maxdepth 1 -type f -regextype posix-extended -regex "$PATTERN_REGEX")

if [[ -z "$files" ]]; then
    echo "[*] No cloud-init log files found — nothing to remediate."
    exit 0
fi

for f in $files; do
    echo "[*] Fixing permissions on: $f"
    chmod u-xs,g-xws,o-xwt "$f"
done

echo "[+] Remediation complete for rule: $RULE_ID"
