#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_custom_logfile"

echo "[*] Applying remediation for: $RULE_ID (configure sudo logfile)"

LOGFILE="/var/log/sudo.log"

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

# If no Defaults logfile defined in /etc/sudoers, append it
if ! grep -P '^[\s]*Defaults\b[^\n]*\blogfile\s*=' /etc/sudoers >/dev/null 2>&1; then
    echo "[*] Adding 'Defaults logfile=${LOGFILE}' to /etc/sudoers"
    echo "Defaults logfile=${LOGFILE}" >> /etc/sudoers
else
    # logfile is defined but may not have the correct value
    escaped_logfile="${LOGFILE//\//\\/}"
    echo "[*] Updating existing Defaults logfile entry in /etc/sudoers to use ${LOGFILE}"
    sed -Ei "s/^([[:space:]]*Defaults[[:space:]].*logfile[[:space:]]*=[[:space:]]*)\"?[^\",[:space:]]+\"?(.*)$/\1${escaped_logfile}\2/" /etc/sudoers
fi

# Validate modified sudoers and handle backup
if /usr/sbin/visudo -qcf /etc/sudoers; then
    echo "[+] visudo validation succeeded after remediation. Removing backup."
    rm -f /etc/sudoers.bak
    echo "[+] Remediation complete: sudo logfile configured as ${LOGFILE}."
else
    echo "[!] visudo validation failed after remediation. Reverting to backup."
    mv /etc/sudoers.bak /etc/sudoers
    exit 1
fi
