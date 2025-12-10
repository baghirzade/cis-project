#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_aide_build_database"

echo "[*] Applying remediation for: $RULE_ID (build AIDE database)"

AIDE_CONFIG="/etc/aide/aide.conf"
DEFAULT_DB_PATH="/var/lib/aide/aide.db"

# Ensure dpkg is available
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, this remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Remediation is applicable only if 'linux-base' is installed (per original SCAP logic)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Ensure AIDE is installed (defensive; previous rule should handle this)
if ! dpkg -s aide >/dev/null 2>&1; then
    echo "[*] AIDE is not installed, installing it now"
    DEBIAN_FRONTEND=noninteractive apt-get install -y aide || {
        echo "[!] Failed to install AIDE package"
        exit 1
    }
fi

# Ensure config file exists
if [ ! -f "$AIDE_CONFIG" ]; then
    echo "[!] AIDE config file not found at $AIDE_CONFIG. This should normally be created by the package."
    echo "[!] No changes applied."
    exit 1
fi

echo "[*] Ensuring database and database_out entries in $AIDE_CONFIG"

# Fix db path in the config file, if necessary
if ! grep -q '^database=file:' "$AIDE_CONFIG"; then
    echo " - Adding database=file:${DEFAULT_DB_PATH}"
    echo "database=file:${DEFAULT_DB_PATH}" >> "$AIDE_CONFIG"
fi

# Fix db out path in the config file, if necessary
if ! grep -q '^database_out=file:' "$AIDE_CONFIG"; then
    echo " - Adding database_out=file:${DEFAULT_DB_PATH}.new"
    echo "database_out=file:${DEFAULT_DB_PATH}.new" >> "$AIDE_CONFIG"
fi

# Initialize / rebuild the AIDE database
if command -v aideinit >/dev/null 2>&1; then
    echo "[*] Running aideinit to build the database"
    /usr/sbin/aideinit -y -f
else
    echo "[!] aideinit not found at /usr/sbin/aideinit. Trying 'aide --init'."
    if command -v aide >/dev/null 2>&1; then
        aide --init
    else
        echo "[!] AIDE binary not found. Cannot initialize database."
        exit 1
    fi
fi

echo "[+] Remediation complete: AIDE database should now be initialized at $DEFAULT_DB_PATH"