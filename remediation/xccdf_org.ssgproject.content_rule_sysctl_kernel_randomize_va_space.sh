#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_kernel_randomize_va_space"
echo "[*] Remediating: $RULE_ID"

# Only applicable when linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] linux-base not installed → skipping remediation."
    exit 0
fi

# ---------------------------------------------------------
# 1. Comment out old entries across sysctl.d locations
# ---------------------------------------------------------

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [[ -f "$f" ]] || continue

    # Skip symlink to main sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then
        continue
    fi

    MATCHES=$(grep -P '^(?!#).*[\s]*kernel.randomize_va_space.*$' "$f" | uniq || true)
    if [[ -n "$MATCHES" ]]; then
        while IFS= read -r entry; do
            escaped=$(sed 's|/|\\/|g' <<< "$entry")
            sed -i --follow-symlinks "s/^${escaped}$/# &/g" "$f"
        done <<< "$MATCHES"
    fi
done

# ---------------------------------------------------------
# 2. Set runtime value
# ---------------------------------------------------------

sysctl -q -n -w kernel.randomize_va_space=2

# ---------------------------------------------------------
# 3. Persist setting into /etc/sysctl.conf
# ---------------------------------------------------------

SYSCONFIG="/etc/sysctl.conf"
KEY="kernel.randomize_va_space"
VALUE="2"
LINE="kernel.randomize_va_space = 2"

if grep -qiE "^${KEY}\>" "$SYSCONFIG"; then
    ESCAPED_LINE=$(sed 's|/|\\/|g' <<< "$LINE")
    sed -i --follow-symlinks "s/^${KEY}\\>.*/$ESCAPED_LINE/gi" "$SYSCONFIG"
else
    # Add new line at bottom safely
    if [[ -s "$SYSCONFIG" ]] && [[ -n "$(tail -c 1 -- "$SYSCONFIG" || true)" ]]; then
        sed -i --follow-symlinks '$a'\\ "$SYSCONFIG"
    fi
    printf '%s\n' "$LINE" >> "$SYSCONFIG"
fi

echo "[+] Remediation complete: kernel.randomize_va_space = 2"
