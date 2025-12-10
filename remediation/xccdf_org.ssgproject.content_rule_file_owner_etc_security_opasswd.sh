#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_security_opasswd"

echo "[*] Applying remediation for: $RULE_ID (Set /etc/security/opasswd user ownership to root)"

TARGET_FILE="/etc/security/opasswd"
EXPECTED_UID="0"

# Check if the file exists before proceeding
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] Remediation not applicable: Target file $TARGET_FILE does not exist. Nothing was done."
    exit 0
fi

newown=""
# Try to resolve UID 0 to a user name (usually 'root')
if id "$EXPECTED_UID" >/dev/null 2>&1; then
    newown="$EXPECTED_UID"
fi

if [[ -z "$newown" ]]; then
    >&2 echo "Error: UID $EXPECTED_UID is not a defined user on the system. Aborting remediation."
    exit 1
fi

echo "[*] Checking and setting user ownership for $TARGET_FILE to $newown (UID $EXPECTED_UID)"

# Check if current UID is not the expected UID
if ! stat -c "%u" "$TARGET_FILE" | grep -E -w -q "$EXPECTED_UID"; then
    echo "    -> Changing user ownership from $(stat -c "%U" "$TARGET_FILE") to $newown"
    
    # chown --no-dereference is used to change user ownership.
    if chown --no-dereference "$newown" "$TARGET_FILE"; then
        echo "[+] Remediation complete: User ownership of $TARGET_FILE set to $newown."
    else
        echo "[!] ERROR: Failed to change user ownership of $TARGET_FILE."
        exit 1
    fi
else
    echo "[+] User ownership of $TARGET_FILE is already correctly set to $newown. No action needed."
fi
