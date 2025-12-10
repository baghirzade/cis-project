#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_permissions_local_var_log"
echo "[*] Applying remediation for: $RULE_ID"

# Skip in containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[!] Container environment detected — skipping"
    exit 0
fi

echo "[*] Fixing insecure permissions for log files in /var/log"

find -P /var/log/ \
    -perm /u+xs,g+xws,o+xwrt \
    ! -name 'history.log*' \
    ! -name 'eipp.log.xz*' \
    ! -name '[bw]tmp' \
    ! -name '[bw]tmp.*' \
    ! -name '[bw]tmp-*' \
    ! -name 'lastlog' \
    ! -name 'lastlog.*' \
    ! -name 'cloud-init.log*' \
    ! -name 'localmessages*' \
    ! -name 'waagent.log*' \
    -type f -regextype posix-extended -regex '.*' \
    -exec chmod u-xs,g-xws,o-xwrt {} \;

echo "[+] Remediation complete: /var/log file permissions corrected"
