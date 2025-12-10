#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_accept_ra"

echo "[*] Applying remediation for: $RULE_ID"

# linux-base must exist
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation not applicable."
    exit 0
fi

TARGET_VALUE="0"
SYSCONFIG_FILE="/etc/sysctl.conf"

echo "[*] Commenting old accept_ra entries in sysctl.d and related configs..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Skip symlink to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv6\.conf\.all\.accept_ra' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            esc=$(printf '%s\n' "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${esc}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

#
# Runtime apply
#
echo "[*] Setting runtime sysctl value net.ipv6.conf.all.accept_ra=$TARGET_VALUE"
sysctl -q -n -w net.ipv6.conf.all.accept_ra="$TARGET_VALUE"

#
# Persist configuration
#
printf_output="net.ipv6.conf.all.accept_ra = $TARGET_VALUE"

echo "[*] Updating $SYSCONFIG_FILE..."

if grep -qi "^net\.ipv6\.conf\.all\.accept_ra" "$SYSCONFIG_FILE"; then
    sed -i --follow-symlinks \
        "s/^net\.ipv6\.conf\.all\.accept_ra.*/$printf_output/I" \
        "$SYSCONFIG_FILE"
else
    # Ensure newline before appending if file lacks one
    if [[ -s "$SYSCONFIG_FILE" ]] && [[ -n "$(tail -c 1 "$SYSCONFIG_FILE" || true)" ]]; then
        echo >> "$SYSCONFIG_FILE"
    fi
    echo "$printf_output" >> "$SYSCONFIG_FILE"
fi

echo "[+] Remediation complete: net.ipv6.conf.all.accept_ra set to 0 (runtime + persistent)"
