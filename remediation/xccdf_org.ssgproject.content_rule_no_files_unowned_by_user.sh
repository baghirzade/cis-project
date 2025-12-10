#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_files_unowned_by_user"
echo "[*] Applying remediation for: $RULE_ID"

# Skip for containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[!] Container environment detected — skipping"
    exit 0
fi

# Find files owned by nonexistent users
bad_files=$(find / -xdev -nouser 2>/dev/null)

if [[ -z "$bad_files" ]]; then
    echo "[*] No unowned files found — nothing to fix"
    exit 0
fi

echo "[*] Fixing user ownership for unowned files..."

for f in $bad_files; do
    if [[ -e "$f" ]]; then
        echo "[*] Setting owner of $f to root"
        chown root:root "$f" || true
    fi
done

echo "[+] Remediation complete: All unowned files assigned to root:root"
