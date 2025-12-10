#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_backup_etc_group"

echo "[*] Applying remediation for: $RULE_ID (Set /etc/group- group ownership to root)"

TARGET_FILE="/etc/group-"
EXPECTED_GID="0"

# Check if the file exists before proceeding
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] Remediation not applicable: Target file $TARGET_FILE does not exist. Nothing was done."
    exit 0
fi

newgroup=""
# Try to resolve GID 0 to a group name (usually 'root')
if getent group "$EXPECTED_GID" >/dev/null 2>&1; then
    newgroup="$EXPECTED_GID"
fi

if [[ -z "${newgroup}" ]]; then
    >&2 echo "Error: GID $EXPECTED_GID is not a defined group on the system. Aborting remediation."
    exit 1
fi

echo "[*] Checking and setting group ownership for $TARGET_FILE to $newgroup (GID $EXPECTED_GID)"

# Check if current GID is not the expected GID
if ! stat -c "%g" "$TARGET_FILE" | grep -E -w -q "$EXPECTED_GID"; then
    echo "    -> Changing group ownership from $(stat -c "%G" "$TARGET_FILE") to $newgroup"
    
    # chgrp --no-dereference is used to change group ownership of the symbolic link itself (if it were a link), 
    # but for a regular file like /etc/group- it changes the file ownership.
    if chgrp --no-dereference "$newgroup" "$TARGET_FILE"; then
        echo "[+] Remediation complete: Group ownership of $TARGET_FILE set to $newgroup."
    else
        echo "[!] ERROR: Failed to change group ownership of $TARGET_FILE."
        exit 1
    fi
else
    echo "[+] Group ownership of $TARGET_FILE is already correctly set to $newgroup. No action needed."
fi
