#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_kernel_module_usb-storage_disabled"
FILE="/etc/modprobe.d/usb-storage.conf"

echo "[*] Remediating: $RULE_ID"

# Platform uyğunluğu
if dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then

    # Faylı yarad (əvvəl yox idisə)
    touch "$FILE"

    # install usb-storage qaydasını düzəlt və ya əlavə et
    if grep -q -m 1 "^install usb-storage" "$FILE"; then
        sed -i 's#^install usb-storage.*#install usb-storage /bin/false#g' "$FILE"
    else
        {
            echo ""
            echo "# Disable per security requirements"
            echo "install usb-storage /bin/false"
        } >> "$FILE"
    fi

    # blacklist usb-storage yoxdursa əlavə et
    if ! grep -q -m 1 "^blacklist usb-storage$" "$FILE"; then
        echo "blacklist usb-storage" >> "$FILE"
    fi

    echo "[+] usb-storage kernel module successfully disabled"
else
    echo "[*] Remediation not applicable — linux-base not installed"
fi

echo "[+] Remediation complete for: $RULE_ID"
