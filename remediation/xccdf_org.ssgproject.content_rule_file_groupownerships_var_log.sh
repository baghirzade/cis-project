#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log"
echo "[*] Applying remediation for: $RULE_ID"

# All non-excluded files must be group-owned by root
target_group="root"

files=$(find -P /var/log/ -type f -regextype posix-extended \
    ! -group root ! -group adm \
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
    ! -regex '.*/lastlog(\.[^\/]+)?$' \
    ! -regex '.*/localmessages(.*)' \
    ! -regex '.*/secure(.*)' \
    ! -regex '.*/waagent.log(.*)' \
    -regex '.*' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No non-compliant files found — nothing to remediate"
    exit 0
fi

while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    grp=$(stat -c %G "$f")

    if [[ "$grp" != "root" && "$grp" != "adm" ]]; then
        echo "[*] Fixing group owner for: $f (current: $grp → new: $target_group)"
        chgrp --no-dereference "$target_group" "$f"
    fi
done <<< "$files"

echo "[+] Remediation complete for $RULE_ID"

