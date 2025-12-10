#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_default_rp_filter"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure platform prerequisite
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base missing; remediation not applicable."
    exit 0
fi

TARGET_VALUE="1"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting incorrect rp_filter entries in sysctl.d/* configs..."

# Process all sysctl configuration files
for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do

    [ -f "$f" ] || continue

    # Skip symlink to the main sysctl file
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv4\.conf\.default\.rp_filter' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESC=$(printf '%s' "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESC}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Applying runtime sysctl setting: rp_filter=$TARGET_VALUE"
sysctl -q -n -w net.ipv4.conf.default.rp_filter="$TARGET_VALUE"

PERSIST_LINE="net.ipv4.conf.default.rp_filter = $TARGET_VALUE"

echo "[*] Updating persistent config in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv4\.conf\.default\.rp_filter" "$SYSCTL_MAIN"; then
    ESC=$(printf '%s' "$PERSIST_LINE" | sed 's|/|\\/|g')
    sed -i --follow-symlinks \
        "s/^net\.ipv4\.conf\.default\.rp_filter.*/$ESC/I" \
        "$SYSCTL_MAIN"
else
    # Ensure newline before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi

    echo "$PERSIST_LINE" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.conf.default.rp_filter set to 1 (runtime + persistent)"
