#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_tcp_syncookies"

echo "[*] Applying remediation for: $RULE_ID"

# Platform validation
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base missing, remediation not applicable"
    exit 0
fi

TARGET_VALUE="1"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect tcp_syncookies entries in sysctl.d configs..."

# Iterate over sysctl configuration files
for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do

    [ -f "$f" ] || continue

    # Skip sysctl.conf symlink
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCH=$(grep -P '^(?!#).*net\.ipv4\.tcp_syncookies' "$f" | uniq || true)

    if [ -n "$MATCH" ]; then
        while IFS= read -r entry; do
            ESCAPED=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESCAPED}$/# &/" "$f"
        done <<< "$MATCH"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -w net.ipv4.tcp_syncookies="$TARGET_VALUE"

PERSIST_LINE="net.ipv4.tcp_syncookies = $TARGET_VALUE"

echo "[*] Updating persistent configuration..."

if grep -qi "^net\.ipv4\.tcp_syncookies" "$SYSCTL_MAIN"; then
    ESC=$(printf "%s" "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv4\.tcp_syncookies.*/$ESC/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.tcp_syncookies set to 1 (runtime + persistent)"
