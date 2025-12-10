#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_grub2_password"
TITLE="GRUB2 must have a superuser and password configured (non-UEFI)"

run() {
    # Non-UEFI GRUB2 üçün klassik Ubuntu/Debian yanaşması
    CUSTOM_FILE="/etc/grub.d/40_custom"
    GRUB_CFG="/boot/grub/grub.cfg"

    # 1. grub2 ümumiyyətlə var?
    if ! command -v grub-mkpasswd-pbkdf2 >/dev/null 2>&1 && \
       ! command -v grub2-mkpasswd-pbkdf2 >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|grub2-mkpasswd-pbkdf2/grub-mkpasswd-pbkdf2 not found (system may not be using grub2)"
        return 0
    fi

    # 2. grub.cfg var?
    if [ ! -f "$GRUB_CFG" ]; then
        echo "WARN|$RULE_ID|$GRUB_CFG does not exist; GRUB2 config not found or system not using classic BIOS grub2 layout"
        return 0
    fi

    # 3. 40_custom var?
    if [ ! -f "$CUSTOM_FILE" ]; then
        echo "WARN|$RULE_ID|$CUSTOM_FILE does not exist; boot loader password for grub2 is likely not configured via 40_custom"
        return 0
    fi

    # 4. superuser sətri var?
    if ! grep -Eq '^[[:space:]]*set[[:space:]]+superusers *= *".+"' "$CUSTOM_FILE"; then
        echo "WARN|$RULE_ID|No 'set superusers=\"...\"' line found in $CUSTOM_FILE"
        return 0
    fi

    # 5. password_pbkdf2 sətri var?
    if ! grep -Eq '^[[:space:]]*password_pbkdf2[[:space:]]+\S+[[:space:]]+grub\.pbkdf2\.sha512\.' "$CUSTOM_FILE"; then
        echo "WARN|$RULE_ID|No 'password_pbkdf2 <user> grub.pbkdf2.sha512.*' line found in $CUSTOM_FILE"
        return 0
    fi

    # 6. grub.cfg-də həmin sətrlər görünürmü? (tam dəqiq yoxlama deyil, amma sanity-check)
    if ! grep -Eq 'password_pbkdf2[[:space:]]+\S+[[:space:]]+grub\.pbkdf2\.sha512\.' "$GRUB_CFG"; then
        echo "WARN|$RULE_ID|Password line not found in $GRUB_CFG; run update-grub after configuring 40_custom"
        return 0
    fi

    echo "OK|$RULE_ID|GRUB2 superuser and PBKDF2 password appear to be configured (40_custom + grub.cfg)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
