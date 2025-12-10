#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_grub2_password"

echo "[*] Applying remediation for: $RULE_ID (set GRUB2 bootloader superuser password)"

# ====== Parametrlər ======
SUPERUSER="${GRUB2_SUPERUSER:-boot}"
HASH="${GRUB2_PASSWORD_HASH:-}"

CUSTOM_FILE="/etc/grub.d/40_custom"
GRUB_CFG_BIOS="/boot/grub/grub.cfg"

# ====== Əsas yoxlamalar ======

# grub2 password aləti varmı?
if ! command -v grub-mkpasswd-pbkdf2 >/dev/null 2>&1 && \
   ! command -v grub2-mkpasswd-pbkdf2 >/dev/null 2>&1; then
    echo "[!] grub-mkpasswd-pbkdf2 / grub2-mkpasswd-pbkdf2 not found. This remediation is only applicable on grub2 systems. Skipping."
    exit 0
fi

# Hash verilməyibsə, avtomatik generasiya ETMİRİK (CIS də bunu belə deyir)
if [[ -z "$HASH" ]]; then
    cat >&2 <<EOF
[!] GRUB2_PASSWORD_HASH environment variable is empty.
    For security reasons this script does NOT auto-generate or hard-code a password.

    1) Generate a PBKDF2 hash on this machine (interactive):
         sudo grub-mkpasswd-pbkdf2
       or (depending on distro):
         sudo grub2-mkpasswd-pbkdf2

    2) Copy the full 'grub.pbkdf2.sha512....' string.

    3) Run this script as:
         GRUB2_PASSWORD_HASH='grub.pbkdf2.sha512.XXXX...' \\
         GRUB2_SUPERUSER='bootadmin' \\
         sudo grub2_password_remediate.sh

    NOTE: GRUB superuser must NOT reuse the system root password.
EOF
    exit 1
fi

# root hüququ lazımdır
if [[ $EUID -ne 0 ]]; then
    echo "[!] This remediation must be run as root. Aborting."
    exit 1
fi

# ====== Backup ======
if [[ -f "$CUSTOM_FILE" ]]; then
    ts="$(date +%F_%H-%M-%S)"
    backup="${CUSTOM_FILE}.bak-${ts}"
    cp -p "$CUSTOM_FILE" "$backup"
    echo "[*] Backup created: $backup"
else
    # fayl yoxdursa, yaradacağıq
    echo "[*] $CUSTOM_FILE does not exist, it will be created."
    touch "$CUSTOM_FILE"
fi

# ====== Mövcud superuser / password sətrlərini təmizlə ======
# Köhnə və ya səhv superuser/password sətrlərini silirik
sed -i -E '/^[[:space:]]*set[[:space:]]+superusers *= *".*"/d' "$CUSTOM_FILE"
sed -i -E '/^[[:space:]]*password_pbkdf2[[:space:]]+\S+[[:space:]]+grub\.pbkdf2\.sha512\./d' "$CUSTOM_FILE"

# Faylın sonuna yeni konfigurasiya əlavə et
cat >> "$CUSTOM_FILE" <<EOF

# CIS / hardening: protect GRUB2 with a superuser + PBKDF2 password
set superusers="${SUPERUSER}"
password_pbkdf2 ${SUPERUSER} ${HASH}
EOF

echo "[*] Updated $CUSTOM_FILE with GRUB2 superuser \"${SUPERUSER}\" and PBKDF2 hash."

# ====== grub.cfg yenilə ======
if command -v update-grub >/dev/null 2>&1; then
    echo "[*] Running update-grub to regenerate $GRUB_CFG_BIOS"
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    # BIOS layout üçün tipik path
    OUT="${GRUB_CFG_BIOS}"
    echo "[*] Running grub2-mkconfig -o $OUT"
    grub2-mkconfig -o "$OUT"
else
    echo "[!] Neither update-grub nor grub2-mkconfig found. Please regenerate grub.cfg manually."
    exit 1
fi

echo "[+] Remediation complete: GRUB2 bootloader superuser and password configured in 40_custom."
echo "[!] WARNING: Misconfiguration of GRUB2 can prevent the system from booting. Test this change carefully."
