#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure pam_unix is enabled via pam-configs)"

(>&2 echo "Remediating rule 37/405: 'xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_enabled'")
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then

conf_name=cac_unix
conf_path="/usr/share/pam-configs"

if [ ! -f "$conf_path"/"$conf_name" ]; then
    if [ -f "$conf_path"/unix ]; then
        if grep -q "$(md5sum "$conf_path"/unix | cut -d ' ' -f 1)" /var/lib/dpkg/info/libpam-runtime.md5sums; then
            cp "$conf_path"/unix "$conf_path"/"$conf_name"
            sed -i 's/Priority: [0-9]\+/Priority: 257\
Conflicts: unix/' "$conf_path"/"$conf_name"
            DEBIAN_FRONTEND=noninteractive pam-auth-update
        else
            echo "Not applicable - checksum of $conf_path/unix does not match the original." >&2
        fi
    else
        echo "Not applicable - $conf_path/unix does not exist" >&2
    fi
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi