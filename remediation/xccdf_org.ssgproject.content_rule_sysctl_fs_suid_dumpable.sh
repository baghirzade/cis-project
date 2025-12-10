#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_fs_suid_dumpable"
echo "[*] Remediating: $RULE_ID"

# Rule applies only on linux-base systems
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] linux-base not installed → skipping remediation."
    exit 0
fi

# ---------------------------------------------------------
# 1. Comment out previous entries in sysctl.d and similar
# ---------------------------------------------------------

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [[ -f "$f" ]] || continue

    # skip symlink pointing to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then
        continue
    fi

    MATCHES=$(grep -P '^(?!#).*[\s]*fs.suid_dumpable.*$' "$f" | uniq || true)
    if [[ -n "$MATCHES" ]]; then
        while IFS= read -r entry; do
            escaped=$(sed -e 's|/|\\/|g' <<< "$entry")
            sed -i --follow-symlinks "s/^${escaped}$/# &/g" "$f"
        done <<< "$MATCHES"
    fi
done

# ---------------------------------------------------------
# 2. Set runtime value
# ---------------------------------------------------------

sysctl -q -n -w fs.suid_dumpable=0

# ---------------------------------------------------------
# 3. Ensure fs.suid_dumpable = 0 exists in /etc/sysctl.conf
# ---------------------------------------------------------

SYSCONFIG="/etc/sysctl.conf"
KEY="fs.suid_dumpable"
VALUE="0"
LINE="fs.suid_dumpable = 0"

if grep -qiE "^${KEY}\>" "$SYSCONFIG"; then
    # Replace existing
    ESCAPED_LINE=$(sed 's|/|\\/|g' <<< "$LINE")
    sed -i --follow-symlinks "s/^${KEY}\\>.*/$ESCAPED_LINE/gi" "$SYSCONFIG"
else
    # Append new line safely
    if [[ -s "$SYSCONFIG" ]] && [[ -n "$(tail -c 1 -- "$SYSCONFIG" || true)" ]]; then
        sed -i --follow-symlinks '$a'\\ "$SYSCONFIG"
    fi
    printf '%s\n' "$LINE" >> "$SYSCONFIG"
fi

echo "[+] Remediation complete: fs.suid_dumpable = 0"
