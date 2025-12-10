#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_all_secure_redirects"

echo "[*] Applying remediation for: $RULE_ID"

# linux-base required
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

TARGET_VALUE="0"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect secure_redirects entries in sysctl.d config files..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Skip the symlink that points back to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv4\.conf\.all\.secure_redirects' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESCAPED=$(printf '%s' "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESCAPED}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv4.conf.all.secure_redirects="$TARGET_VALUE"

PERSIST_LINE="net.ipv4.conf.all.secure_redirects = $TARGET_VALUE"

echo "[*] Updating persistent entry in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv4\.conf\.all\.secure_redirects" "$SYSCTL_MAIN"; then
    ESCAPED=$(printf '%s' "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv4\.conf\.all\.secure_redirects.*/$ESCAPED/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.conf.all.secure_redirects set to 0 (runtime + persistent)"
