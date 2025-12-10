#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_grub2_uefi_password"

echo "[*] Applying remediation for: $RULE_ID (configure GRUB2 UEFI password)"

GRUB_CFG="/boot/efi/EFI/*/grub.cfg"
GRUB_USER="root"

# Ensure grub.cfg exists
if ! ls $GRUB_CFG >/dev/null 2>&1; then
    echo "[!] grub.cfg not found under /boot/efi/EFI/. Remediation skipped."
    exit 0
fi

# Prompt for password (secure input)
echo "[*] Please enter new GRUB2 password for user '$GRUB_USER':"
read -r -s GRUB_PASSWORD

# Generate PBKDF2 hash
GRUB_HASH=$(echo -e "$GRUB_PASSWORD\n$GRUB_PASSWORD" | grub-mkpasswd-pbkdf2 | awk '/PBKDF2 hash of your password is/{print $NF}')

if [ -z "$GRUB_HASH" ]; then
    echo "[!] Failed to generate PBKDF2 hash. Remediation aborted."
    exit 1
fi

# Insert into grub.cfg if not present
if ! grep -q "password_pbkdf2 $GRUB_USER" $GRUB_CFG; then
    echo "set superusers=\"$GRUB_USER\"" >> $GRUB_CFG
    echo "password_pbkdf2 $GRUB_USER $GRUB_HASH" >> $GRUB_CFG
    echo "[+] GRUB2 UEFI password configured for user '$GRUB_USER'."
else
    sed -i "s|^password_pbkdf2 $GRUB_USER .*|password_pbkdf2 $GRUB_USER $GRUB_HASH|" $GRUB_CFG
    echo "[+] GRUB2 UEFI password updated for user '$GRUB_USER'."
fi
