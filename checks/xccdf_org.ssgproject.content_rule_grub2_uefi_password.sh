#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_grub2_uefi_password"
TITLE="GRUB2 must have UEFI password configured"

run() {
    GRUB_CFG="/boot/efi/EFI/*/grub.cfg"

    # Check if grub.cfg exists
    if ! ls $GRUB_CFG >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|grub.cfg not found under /boot/efi/EFI/"
        return 0
    fi

    # Check if password_pbkdf2 is configured
    if ! grep -q "password_pbkdf2" $GRUB_CFG 2>/dev/null; then
        echo "WARN|$RULE_ID|No password_pbkdf2 entry found in grub.cfg"
        return 0
    fi

    echo "OK|$RULE_ID|GRUB2 UEFI password is configured in grub.cfg"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
