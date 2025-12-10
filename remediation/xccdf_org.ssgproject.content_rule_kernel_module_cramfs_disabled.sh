#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_cramfs_disabled"
FILE="/etc/modprobe.d/cramfs.conf"

echo "[*] Remediating: $RULE_ID"

# Platform check
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Fayl mövcud deyilsə yaradılır
    touch "$FILE"

    # install cramfs qaydasını düzəlt
    if grep -q -m 1 "^install cramfs" "$FILE"; then
        sed -i 's#^install cramfs.*#install cramfs /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install cramfs /bin/false"
        } >> "$FILE"
    fi

    # blacklist cramfs yoxdursa əlavə olunur
    if ! grep -q -m 1 "^blacklist cramfs$" "$FILE"; then
        echo "blacklist cramfs" >> "$FILE"
    fi

    echo "[+] cramfs kernel module disabled"

else
    echo "[*] Remediation is not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
