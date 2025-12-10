#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_remove_no_authenticate"

echo "[*] Applying remediation for: $RULE_ID (remove !authenticate from sudoers)"

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

# -------------------------
# Handle /etc/sudoers
# -------------------------
if [ -f /etc/sudoers ]; then
    # Backup main sudoers
    cp /etc/sudoers /etc/sudoers.bak_no_authenticate

    # Comment non-comment lines that contain !authenticate
    if grep -P '^(?!#).*[\s]+\!authenticate.*$' /etc/sudoers >/dev/null 2>&1; then
        echo "[*] Commenting !authenticate entries in /etc/sudoers"
        sed -ri 's/^([^#].*\s!authenticate.*)$/# \1/' /etc/sudoers
    else
        echo "[i] No active !authenticate entries found in /etc/sudoers"
    fi

    # Validate modified sudoers and handle backup
    if /usr/sbin/visudo -qcf /etc/sudoers; then
        echo "[+] visudo validation for /etc/sudoers succeeded after remediation. Removing backup."
        rm -f /etc/sudoers.bak_no_authenticate
    else
        echo "[!] visudo validation for /etc/sudoers failed after remediation. Reverting to backup."
        mv /etc/sudoers.bak_no_authenticate /etc/sudoers
        # Do not exit here; continue with sudoers.d but signal error to caller
        exit 1
    fi
else
    echo "[!] /etc/sudoers does not exist; skipping main sudoers file."
fi

# -------------------------
# Handle /etc/sudoers.d/*
# -------------------------
if [ -d /etc/sudoers.d ]; then
    for f in /etc/sudoers.d/* ; do
        # Skip if glob didn't match anything
        [ -e "$f" ] || continue

        if grep -P '^(?!#).*[\s]+\!authenticate.*$' "$f" >/dev/null 2>&1; then
            echo "[*] Commenting !authenticate entries in $f"
            sed -ri 's/^([^#].*\s!authenticate.*)$/# \1/' "$f"

            # Validate with visudo -cf
            if /usr/sbin/visudo -cf "$f" >/dev/null 2>&1; then
                echo "[+] visudo validation for $f succeeded after remediation."
            else
                echo "[!] Fail to validate $f with visudo after remediation."
            fi
        else
            echo "[i] No active !authenticate entries found in $f"
        fi
    done
fi

echo "[+] Remediation complete: active !authenticate entries in sudoers have been commented out (where possible)."
