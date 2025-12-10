#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log"
echo "[*] Applying remediation for: $RULE_ID"

# Target owner is always root
target_owner="root"

# Identify non-compliant files
files=$(find -P /var/log/ -type f -regextype posix-extended \
    ! -user root ! -user syslog \
    ! -name 'gdm' ! -name 'gdm3' \
    ! -name 'sssd' ! -name 'SSSD' \
    ! -name 'auth.log' \
    ! -name 'messages' \
    ! -name 'syslog' \
    ! -path '/var/log/apt/*' \
    ! -path '/var/log/landscape/*' \
    ! -path '/var/log/gdm/*' \
    ! -path '/var/log/gdm3/*' \
    ! -path '/var/log/sssd/*' \
    ! -path '/var/log/[bw]tmp*' \
    ! -path '/var/log/cloud-init.log*' \
    ! -regex '.*\.journal[~]?' \
    ! -regex '.*/lastlog(\.[^/]+)?$' \
    ! -regex '.*/localmessages(.*)' \
    ! -regex '.*/secure(.*)' \
    ! -regex '.*/waagent.log(.*)' \
    -regex '.*')

if [[ -z "$files" ]]; then
    echo "[*] No files require remediation."
    exit 0
fi

# Apply owner fix
while IFS= read -r f; do
    echo "[*] Fixing ownership: $f → root"
    chown --no-dereference "$target_owner" "$f"
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"
