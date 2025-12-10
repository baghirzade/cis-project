#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_all_accept_redirects"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
 | grep -q '^installed$'; then
    echo "[!] linux-base not installed; skipping remediation."
    exit 0
fi

TARGET="0"
SYSCTL_MAIN="/etc/sysctl.conf"

echo "[*] Commenting non-compliant settings in sysctl.d directories..."

for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
    [ -f "$f" ] || continue

    # Skip symlink to sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    MATCHES=$(grep -P '^(?!#).*net\.ipv4\.conf\.all\.accept_redirects' "$f" | uniq || true)

    if [ -n "$MATCHES" ]; then
        while IFS= read -r entry; do
            ESCAPED=$(printf "%s" "$entry" | sed 's|/|\\/|g')
            sed -i --follow-symlinks "s/^${ESCAPED}$/# &/" "$f"
        done <<< "$MATCHES"
    fi
done

echo "[*] Setting runtime sysctl value..."
sysctl -q -n -w net.ipv4.conf.all.accept_redirects="$TARGET"

PERSIST="net.ipv4.conf.all.accept_redirects = $TARGET"

echo "[*] Updating persistent configuration in $SYSCTL_MAIN..."

if grep -qi "^net\.ipv4\.conf\.all\.accept_redirects" "$SYSCTL_MAIN"; then
    ESCAPED=$(printf "%s" "$PERSIST" | sed 's|/|\\/|g')
    sed -i --follow-symlinks "s/^net\.ipv4\.conf\.all\.accept_redirects.*/$ESCAPED/I" "$SYSCTL_MAIN"
else
    # Ensure newline before appending
    if [[ -s "$SYSCTL_MAIN" ]] && [[ -n "$(tail -c 1 "$SYSCTL_MAIN" || true)" ]]; then
        echo >> "$SYSCTL_MAIN"
    fi
    echo "$PERSIST" >> "$SYSCTL_MAIN"
fi

echo "[+] Remediation complete: net.ipv4.conf.all.accept_redirects set to 0 (runtime + persistent)"
