#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_journald_storage"

echo "[*] Applying remediation for: $RULE_ID (set systemd-journald Storage=persistent)"

# Debian/Ubuntu check
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# linux-base paketi yoxdursa, SCAP loqikasına görə applicable deyil
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation not applicable. Skipping."
    exit 0
fi

# Bu qayda yalnız rsyslog aktiv DEYİLKƏN tətbiq olunur
if systemctl is-active rsyslog &>/dev/null; then
    echo "[!] rsyslog service is active; control expects journald-only logging. No changes applied."
    exit 0
fi

CONF="/etc/systemd/journald.conf"
BAK="${CONF}.bak"

# Konfiqurasiya faylını hazırla
if [ -e "$CONF" ] ; then
    # Mövcud Storage= sətirlərini sil
    LC_ALL=C sed -i "/^\s*Storage\s*=\s*/d" "$CONF"
else
    touch "$CONF"
fi

# Faylın sonunda newline olduğuna əmin ol
sed -i -e '$a\' "$CONF"

cp "$CONF" "$BAK"

# '# Storage' komment sətrindən əvvəl əlavə et
line_number="$(LC_ALL=C grep -n "^#\s*Storage" "$BAK" | LC_ALL=C sed 's/:.*//g')"
if [ -z "$line_number" ]; then
    # '^#\s*Storage' tapılmadısa, faylın sonuna yaz
    printf '%s\n' "Storage=persistent" >> "$CONF"
else
    head -n "$(( line_number - 1 ))" "$BAK" > "$CONF"
    printf '%s\n' "Storage=persistent" >> "$CONF"
    tail -n "+$(( line_number ))" "$BAK" >> "$CONF"
fi

rm -f "$BAK"

echo "[+] Remediation complete: Storage=persistent is now configured in $CONF"

