#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_hfs_disabled"
FILE="/etc/modprobe.d/hfs.conf"

echo "[*] Remediating: $RULE_ID"

# Platform check
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Faylı yaradın (əgər yoxdur)
    touch "$FILE"

    # 'install hfs' sətrini düzəlt və ya əlavə et
    if grep -q -m 1 "^install hfs" "$FILE"; then
        sed -i 's#^install hfs.*#install hfs /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install hfs /bin/false"
        } >> "$FILE"
    fi

    # blacklist qaydası əlavə et, əgər yoxdursa
    if ! grep -q -m 1 "^blacklist hfs$" "$FILE"; then
        echo "blacklist hfs" >> "$FILE"
    fi

    echo "[+] hfs kernel module disabled successfully"

else
    echo "[*] Remediation not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
