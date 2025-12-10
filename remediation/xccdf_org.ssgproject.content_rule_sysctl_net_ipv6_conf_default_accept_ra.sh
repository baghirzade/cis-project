#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_default_accept_ra"

echo "[*] Applying remediation for: $RULE_ID"

# linux-base required
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base package not installed; remediation not applicable."
    exit 0
fi

TARGET_VALUE="0"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting old/default accept_ra entries in sysctl.d locations..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Avoid modifying symlink to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv6\.conf\.default\.accept_ra' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESCAPED=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESCAPED}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv6.conf.default.accept_ra="$TARGET_VALUE"

PERSIST_LINE="net.ipv6.conf.default.accept_ra = $TARGET_VALUE"

echo "[*] Updating persistent configuration in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv6\.conf\.default\.accept_ra" "$SYSCTL_MAIN"; then
    ESCAPED=$(printf "%s" "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv6\.conf\.default\.accept_ra.*/$ESCAPED/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline before append
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv6.conf.default.accept_ra set to 0 (runtime + persistent)"
