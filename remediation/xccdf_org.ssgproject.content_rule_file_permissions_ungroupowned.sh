#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_ungroupowned"
echo "[*] Applying remediation for: $RULE_ID"

# Skip inside containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[!] Container environment detected — skipping"
    exit 0
fi

# Find files with non-existent group owner
bad_files=$(find / -xdev -nogroup 2>/dev/null)

if [[ -z "$bad_files" ]]; then
    echo "[*] No ungroupowned files found — nothing to fix"
    exit 0
fi

echo "[*] Fixing group ownership for ungroupowned files..."

for f in $bad_files; do
    if [[ -e "$f" ]]; then
        echo "[*] Setting group owner of $f to root"
        chgrp root "$f" || true
    fi
done

echo "[+] Remediation complete: All ungroupowned files assigned to root group"
