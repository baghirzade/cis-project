#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_hfsplus_disabled"
FILE="/etc/modprobe.d/hfsplus.conf"

echo "[*] Remediating: $RULE_ID"

# Platform check
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Fayl yoxdursa, yarat
    touch "$FILE"

    # install hfsplus qaydasını təyin et
    if grep -q -m 1 "^install hfsplus" "$FILE"; then
        sed -i 's#^install hfsplus.*#install hfsplus /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install hfsplus /bin/false"
        } >> "$FILE"
    fi

    # blacklist qaydasını əlavə et
    if ! grep -q -m 1 "^blacklist hfsplus$" "$FILE"; then
        echo "blacklist hfsplus" >> "$FILE"
    fi

    echo "[+] hfsplus kernel module disabled successfully"

else
    echo "[*] Remediation not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
