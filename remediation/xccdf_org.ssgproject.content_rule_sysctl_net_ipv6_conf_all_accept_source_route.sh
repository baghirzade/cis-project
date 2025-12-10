#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_accept_source_route"

echo "[*] Applying remediation for: $RULE_ID"

# linux-base check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base not installed; skipping."
    exit 0
fi

TARGET=0
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting outdated accept_source_route entries..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Skip systemd symlink → /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv6\.conf\.all\.accept_source_route' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            esc=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${esc}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv6.conf.all.accept_source_route="$TARGET"

PERSIST_LINE="net.ipv6.conf.all.accept_source_route = $TARGET"

echo "[*] Updating $SYSCTL_MAIN..."

# Replace existing entry or append if missing
if grep -qi "^net\.ipv6\.conf\.all\.accept_source_route" "$SYSCTL_MAIN"; then
    esc=$(printf "%s" "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv6\.conf\.all\.accept_source_route.*/$esc/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv6.conf.all.accept_source_route set to 0 (runtime + persistent)"
