#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_require_reauthentication"

echo "[*] Applying remediation for: $RULE_ID (configure sudo timestamp_timeout=15)"

REQUIRED_TIMEOUT="15"

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
    echo "[!] /usr/sbin/visudo not found; cannot safely modify sudoers."
    exit 1
fi

# Validate current sudoers
if ! /usr/sbin/visudo -qcf /etc/sudoers; then
    echo "[!] Skipping remediation: /etc/sudoers failed validation via visudo."
    exit 1
fi

# -------------------------
# Clean timestamp_timeout from /etc/sudoers.d/*
# -------------------------
if [ -d /etc/sudoers.d ]; then
    echo "[*] Removing timestamp_timeout definitions from /etc/sudoers.d"
    find /etc/sudoers.d/ -type f -exec \
        sed -Ei "/^[[:blank:]]*Defaults.*timestamp_timeout[[:blank:]]*=.*/d" {} \;
fi

# -------------------------
# Configure timestamp_timeout in /etc/sudoers
# -------------------------

# Backup sudoers
cp /etc/sudoers /etc/sudoers.bak_timestamp_timeout

if ! grep -P '^[\s]*Defaults.*timestamp_timeout[\s]*=' /etc/sudoers >/dev/null 2>&1; then
    echo "[*] Adding 'Defaults timestamp_timeout=${REQUIRED_TIMEOUT}' to /etc/sudoers"
    echo "Defaults timestamp_timeout=${REQUIRED_TIMEOUT}" >> /etc/sudoers
else
    echo "[*] Updating existing timestamp_timeout in /etc/sudoers to ${REQUIRED_TIMEOUT}"
    sed -Ei "s/^([[:blank:]]*Defaults.*timestamp_timeout[[:blank:]]*=[[:blank:]]*)[-]?[0-9]+(.*)$/\1${REQUIRED_TIMEOUT}\2/" /etc/sudoers
fi

# Validate modified sudoers and handle backup
if /usr/sbin/visudo -qcf /etc/sudoers; then
    echo "[+] visudo validation succeeded after remediation. Removing backup."
    rm -f /etc/sudoers.bak_timestamp_timeout
    echo "[+] Remediation complete: sudo timestamp_timeout configured as ${REQUIRED_TIMEOUT} in /etc/sudoers and not overridden in /etc/sudoers.d."
else
    echo "[!] visudo validation failed after remediation. Reverting to backup."
    mv /etc/sudoers.bak_timestamp_timeout /etc/sudoers
    exit 1
fi
