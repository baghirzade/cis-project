#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_systemd_journal_upload_server_tls"
TITLE="systemd-journal-upload.service must be configured to use TLS for server-side connections"

run() {
    # Remediation is applicable only in certain platforms
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'linux-base' paketi quraşdırılmayıb (Debian/Ubuntu olmayan sistem)"
        return 0
    fi
    
    # Check if rsyslog is inactive, as systemd-journal-upload might be used then
    if systemctl is-active rsyslog &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|rsyslog aktivdir, systemd-journal-upload-a ehtiyac yoxdur."
        return 0
    fi

    # Check if journal-upload.service is installed/enabled
    if ! systemctl list-unit-files | grep -q 'systemd-journal-upload.service'; then
        echo "NOTAPPL|$RULE_ID|systemd-journal-upload.service mövcud deyil."
        return 0
    fi

    local_conf_files="/etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*.conf"
    
    # Tələb olunan dəyərlər
    var_key_file='/etc/pki/systemd/private/journal-upload.pem'
    var_cert_file='/etc/pki/systemd/certs/journal-upload.pem'
    var_trusted_cert_file='/etc/pki/systemd/ca/trusted.pem'

    # Funksiya: Verilmiş açarın verilmiş konfiqurasiya fayllarında düzgün dəyərlə konfiqurasiya edilib-edilmədiyini yoxlayır
    check_config_value() {
        local key="$1"
        local expected_value="$2"
        local is_ok=false

        # Bütün konfiqurasiya fayllarında yoxlama
        for conf_file in $local_conf_files; do
            [[ -e "${conf_file}" ]] || continue

            # 'Upload' bölməsində açar və dəyərin yoxlanılması
            if grep -qPzos "[[:space:]]*\[Upload\]([^\n\[]*\n+)+?[[:space:]]*${key}\s*=\s*${expected_value}\s*$" "$conf_file"; then
                is_ok=true
                break
            fi
        done
        
        if $is_ok; then
            return 0 # OK
        else
            return 1 # NOT OK
        fi
    }

    # Bütün 3 açarın yoxlanılması
    if ! check_config_value "ServerKeyFile" "$var_key_file"; then
        echo "FAIL|$RULE_ID|ServerKeyFile=$var_key_file konfiqurasiya edilməyib və ya kilidlənməyib."
        return 1
    fi

    if ! check_config_value "ServerCertificateFile" "$var_cert_file"; then
        echo "FAIL|$RULE_ID|ServerCertificateFile=$var_cert_file konfiqurasiya edilməyib və ya kilidlənməyib."
        return 1
    fi

    if ! check_config_value "TrustedCertificateFile" "$var_trusted_cert_file"; then
        echo "FAIL|$RULE_ID|TrustedCertificateFile=$var_trusted_cert_file konfiqurasiya edilməyib və ya kilidlənməyib."
        return 1
    fi

    echo "OK|$RULE_ID|systemd-journal-upload TLS sertifikat yolları düzgün konfiqurasiya edilib."
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
