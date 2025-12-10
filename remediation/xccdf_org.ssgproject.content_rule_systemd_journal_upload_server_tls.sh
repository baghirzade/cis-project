#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_systemd_journal_upload_server_tls"

echo "[*] Applying remediation for: $RULE_ID (systemd-journal-upload server TLS files)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' && { ! (systemctl is-active rsyslog &>/dev/null); }; then

dropin_conf='/etc/systemd/journal-upload.conf.d/60-journald_upload.conf'
mkdir -p /etc/systemd/journal-upload.conf.d
touch "${dropin_conf}"

# Bütün mövcud konfiqurasiya fayllarında (həm əsas, həm də drop-in) əvvəlki dəyərləri rəyə çevir
for conf in /etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*.conf; do
    [[ -e "${conf}" ]] || continue
    sed -i --follow-symlinks \
        -e 's/^ServerKeyFile\s*=/;&/g' \
        -e 's/^ServerCertificateFile\s*=/;&/g' \
        -e 's/^TrustedCertificateFile\s*=/;&/g' "${conf}" || true
done

# Tələb olunan dəyişkənlər
var_journal_upload_server_key_file='/etc/pki/systemd/private/journal-upload.pem'
var_journal_upload_server_certificate_file='/etc/pki/systemd/certs/journal-upload.pem'
var_journal_upload_server_trusted_certificate_file='/etc/pki/systemd/ca/trusted.pem'

# Konfiqurasiya dəyərlərinin təyin edilməsi üçün dövr
CONFIG_SETTINGS=(
    "ServerKeyFile=$var_journal_upload_server_key_file"
    "ServerCertificateFile=$var_journal_upload_server_certificate_file"
    "TrustedCertificateFile=$var_journal_upload_server_trusted_certificate_file"
)

# [Upload] bölməsini drop-in faylına əlavə et
if ! grep -q "^\s*\[Upload\]" "$dropin_conf"; then
    echo -e "\n[Upload]\n" >> "$dropin_conf"
fi

for setting in "${CONFIG_SETTINGS[@]}"; do
    KEY=$(echo "$setting" | cut -d'=' -f1)
    VALUE=$(echo "$setting" | cut -d'=' -f2-)
    
    # Açarın mövcud olub-olmadığını yoxla və dəyəri yenilə
    if grep -qPzos "[[:space:]]*\[Upload\]([^\n\[]*\n+)+?[[:space:]]*${KEY}\s*=" "$dropin_conf"; then
        sed -i "s/^\s*${KEY}\s*=.*/${KEY}=${VALUE}/" "$dropin_conf"
    # Açar mövcud deyilsə, [Upload] bölməsinin altına əlavə et
    else
        sed -i "/\[Upload\]/a ${KEY}=${VALUE}" "$dropin_conf"
    fi
done

# systemd konfiqurasiyasını yenilə
if systemctl daemon-reload &>/dev/null; then
    echo "[+] systemd daemon-reload uğurla həyata keçirildi."
fi

echo "[+] Remediation complete: systemd-journal-upload.service TLS sertifikat yolları konfiqurasiya edildi."

else
    echo "[!] Remediation is not applicable (Check: 'linux-base' installed and rsyslog inactive). No changes applied."
fi
