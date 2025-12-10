#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_add_use_pty"

echo "[*] Applying remediation for: $RULE_ID (ensure Defaults use_pty in sudoers)"

# Only Debian/Ubuntu systems have dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicability: linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# sudo must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] sudo is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

if [ ! -x /usr/sbin/visudo ]; then
    echo "[!] /usr/sbin/visudo not found; cannot safely modify /etc/sudoers."
    exit 1
fi

# Validate current sudoers
if ! /usr/sbin/visudo -qcf /etc/sudoers; then
    echo "[!] Skipping remediation: /etc/sudoers failed validation via visudo."
    exit 1
fi

# Backup sudoers
cp /etc/sudoers /etc/sudoers.bak

# If no Defaults use_pty present, append it
if ! grep -P '^[\s]*Defaults\b[^!\n]*\buse_pty\b' /etc/sudoers >/dev/null 2>&1; then
    echo "[*] Adding 'Defaults use_pty' to /etc/sudoers"
    echo "Defaults use_pty" >> /etc/sudoers
else
    echo "[i] 'Defaults use_pty' is already present in /etc/sudoers"
fi

# Validate modified sudoers and handle backup
if /usr/sbin/visudo -qcf /etc/sudoers; then
    echo "[+] visudo validation succeeded after remediation. Removing backup."
    rm -f /etc/sudoers.bak
    echo "[+] Remediation complete: Defaults use_pty is configured in /etc/sudoers."
else
    echo "[!] visudo validation failed after remediation. Reverting to backup."
    mv /etc/sudoers.bak /etc/sudoers
    exit 1
fi
