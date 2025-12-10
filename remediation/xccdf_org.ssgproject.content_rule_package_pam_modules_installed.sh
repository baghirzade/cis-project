#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_pam_modules_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure libpam-modules is installed)"

(>&2 echo "Remediating rule 34/405: 'xccdf_org.ssgproject.content_rule_package_pam_modules_installed'")
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then

DEBIAN_FRONTEND=noninteractive apt-get install -y "libpam-modules"

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi
