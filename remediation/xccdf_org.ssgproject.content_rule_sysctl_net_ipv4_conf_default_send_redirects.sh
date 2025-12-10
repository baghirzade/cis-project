#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_default_send_redirects"

echo "[*] Applying remediation for: $RULE_ID"

# Required package check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed, skipping remediation"
    exit 0
fi

TARGET_VALUE="0"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect send_redirects entries in sysctl.d configs..."

# Iterate through config sources
for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do

    [ -f "$f" ] || continue

    # Skip sysctl.conf symlink
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv4\.conf\.default\.send_redirects' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESC=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESC}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Applying runtime sysctl value..."
sysctl -q -w net.ipv4.conf.default.send_redirects="$TARGET_VALUE"

PERSIST_LINE="net.ipv4.conf.default.send_redirects = $TARGET_VALUE"

echo "[*] Updating persistent sysctl configuration..."

if grep -qi "^net\.ipv4\.conf\.default\.send_redirects" "$SYSCTL_MAIN"; then
    ESC=$(printf "%s" "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv4\.conf\.default\.send_redirects.*/$ESC/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline at end before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.conf.default.send_redirects set to 0 (runtime + persistent)"
