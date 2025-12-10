#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_pub_key"

echo "[*] Applying remediation for: $RULE_ID (Remove dangerous permissions from SSHD public key files)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

echo "    -> Searching for and correcting permissions on *.pub files in /etc/ssh/ (maxdepth 1)."

# The remediation command uses chmod to remove setuid (u-xs), setgid (g-xws), and sticky (o-xwt) bits.
find -P /etc/ssh/ -maxdepth 1 -perm /u+xs,g+xws,o+xwt -type f -regextype posix-extended -regex '^.*\.pub$' -exec chmod u-xs,g-xws,o-xwt {} \;

echo "[+] Remediation complete. Dangerous permissions removed from SSHD public key files."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
