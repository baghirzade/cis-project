#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_jffs2_disabled"
FILE="/etc/modprobe.d/jffs2.conf"

echo "[*] Remediating: $RULE_ID"

# Platform check
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Fayl yoxdursa, yarat
    touch "$FILE"

    # install jffs2 qaydasını təyin et
    if grep -q -m 1 "^install jffs2" "$FILE"; then
        sed -i 's#^install jffs2.*#install jffs2 /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install jffs2 /bin/false"
        } >> "$FILE"
    fi

    # blacklist qaydasını əlavə et
    if ! grep -q -m 1 "^blacklist jffs2$" "$FILE"; then
        echo "blacklist jffs2" >> "$FILE"
    fi

    echo "[+] jffs2 kernel module disabled successfully"

else
    echo "[*] Remediation not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
