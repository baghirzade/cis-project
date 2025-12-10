#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_systemd_journal_upload_url"

echo "[*] Applying remediation for: $RULE_ID (Set systemd-journal-upload URL)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' && { ! (systemctl is-active rsyslog &>/dev/null); }; then

dropin_conf='/etc/systemd/journal-upload.conf.d/60-journald_upload.conf'
mkdir -p /etc/systemd/journal-upload.conf.d
touch "${dropin_conf}"

# Comment out existing URL settings in other configuration files
for conf in /etc/systemd/journal-upload.conf /etc/systemd/journal-upload.conf.d/*; do
    [[ -e "${conf}" ]] || continue
    sed -i --follow-symlinks 's/^URL\s*=/;&/g' "${conf}" || true
done

# Required variable
var_journal_upload_url='remotelogserver'

found=false
file="${dropin_conf}"

# Ensure [Upload] section exists in the drop-in file
if ! grep -q "^\s*\[Upload\]" "$file"; then
    echo -e "\n[Upload]\n" >> "$file"
fi

# Set value in the drop-in file
if [ ! -e "$file" ]; then
    echo "[!] Drop-in file $file not found. Aborting URL configuration."
    exit 1
fi

# 1. find key in section and change value
if grep -qzosP "[[:space:]]*\[Upload\]([^\n\[]*\n+)+?[[:space:]]*URL" "$file"; then
    sed -i "s/^\s*URL\s*=.*/URL=${var_journal_upload_url}/" "$file"
    found=true

# 2. find section and add key = value to it
elif grep -qs "[[:space:]]*\[Upload\]" "$file"; then
    sed -i "/[[:space:]]*\[Upload\]/a URL=${var_journal_upload_url}" "$file"
    found=true
fi

# If for some reason the section/key wasn't set (shouldn't happen with the check above, but for safety)
if ! $found ; then
    echo -e "[Upload]\nURL=${var_journal_upload_url}" >> "$file"
fi

# Reload systemd configuration
if systemctl daemon-reload &>/dev/null; then
    echo "[+] systemd daemon-reload successfully executed."
fi

echo "[+] Remediation complete: systemd-journal-upload URL is set to '${var_journal_upload_url}'."

else
    echo "[!] Remediation is not applicable (Check: 'linux-base' installed and rsyslog inactive). No changes applied."
fi
