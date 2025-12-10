#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_accept_redirects"

echo "[*] Applying remediation for: $RULE_ID"

# Deb/Ubuntu only
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed, remediation not applicable."
    exit 0
fi

TARGET_VALUE="0"
SYSCONFIG_FILE="/etc/sysctl.conf"

echo "[*] Commenting non-compliant entries in sysctl.d directories..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # skip symlink → /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv6\.conf\.all\.accept_redirects' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            esc=$(printf '%s' "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${esc}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv6.conf.all.accept_redirects="$TARGET_VALUE"

printf_output="net.ipv6.conf.all.accept_redirects = $TARGET_VALUE"

echo "[*] Updating persistent config in $SYSCONFIG_FILE..."

if grep -qi "^net\.ipv6\.conf\.all\.accept_redirects" "$SYSCONFIG_FILE"; then
    escaped=$(printf '%s' "$printf_output" | sed 's|/|\\/|g')
    sed -i --follow-symlinks "s/^net\.ipv6\.conf\.all\.accept_redirects.*/$escaped/I" "$SYSCONFIG_FILE"
else
    # Ensure newline before append if needed
    if [[ -s "$SYSCONFIG_FILE" ]] && [[ -n "$(tail -c 1 "$SYSCONFIG_FILE" || true)" ]]; then
        echo >> "$SYSCONFIG_FILE"
    fi
    echo "$printf_output" >> "$SYSCONFIG_FILE"
fi

echo "[+] Remediation complete: net.ipv6.conf.all.accept_redirects set to 0 (runtime + persistent)"
