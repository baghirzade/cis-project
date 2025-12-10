#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_forwarding"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure linux-base exists
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base not installed; skipping remediation."
    exit 0
fi

TARGET=0
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect forwarding settings in sysctl.d directories..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Skip symlink to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv6\.conf\.all\.forwarding' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            esc=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${esc}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv6.conf.all.forwarding="$TARGET"

PERSIST_LINE="net.ipv6.conf.all.forwarding = $TARGET"

echo "[*] Updating persistent configuration in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv6\.conf\.all\.forwarding" "$SYSCTL_MAIN"; then
    esc=$(printf "%s" "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv6\.conf\.all\.forwarding.*/$esc/I" \
        "$SYSCTL_MAIN"
else
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv6.conf.all.forwarding set to 0 (runtime + persistent)"
