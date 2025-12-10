#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_icmp_echo_ignore_broadcasts"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure system is applicable
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base not installed, remediation not applicable."
    exit 0
fi

TARGET_VALUE="1"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect icmp_echo_ignore_broadcasts entries..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do

    [ -f "$f" ] || continue

    # Skip sysctl.conf symlink
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv4\.icmp_echo_ignore_broadcasts' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESC=$(printf '%s' "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESC}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv4.icmp_echo_ignore_broadcasts="$TARGET_VALUE"

PERSIST_LINE="net.ipv4.icmp_echo_ignore_broadcasts = $TARGET_VALUE"

echo "[*] Updating persistent configuration in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv4\.icmp_echo_ignore_broadcasts" "$SYSCTL_MAIN"; then
    ESC=$(printf '%s' "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv4\.icmp_echo_ignore_broadcasts.*/$ESC/I" \
        "$SYSCTL_MAIN"
else
    # add newline if last line has no newline
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then 
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.icmp_echo_ignore_broadcasts set to 1 (runtime + persistent)"
