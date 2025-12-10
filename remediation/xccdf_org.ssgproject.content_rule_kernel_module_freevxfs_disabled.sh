#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_freevxfs_disabled"
FILE="/etc/modprobe.d/freevxfs.conf"

echo "[*] Remediating: $RULE_ID"

# Platform check
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Fayl yoxdursa yaradılır
    touch "$FILE"

    # install freevxfs qaydasını düzəlt
    if grep -q -m 1 "^install freevxfs" "$FILE"; then
        sed -i 's#^install freevxfs.*#install freevxfs /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install freevxfs /bin/false"
        } >> "$FILE"
    fi

    # blacklist qaydası
    if ! grep -q -m 1 "^blacklist freevxfs$" "$FILE"; then
        echo "blacklist freevxfs" >> "$FILE"
    fi

    echo "[+] freevxfs kernel module disabled"
else
    echo "[*] Remediation is not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
