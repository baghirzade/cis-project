#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_sshd_config"

echo "[*] Applying remediation for: $RULE_ID (Ensure SSHD configuration file group owner is root)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

TARGET_FILE="/etc/ssh/sshd_config"
EXPECTED_GROUP="root"

if [ -f "$TARGET_FILE" ]; then

    newgroup=""
    # Check if GID 0 (root) is a defined group
    if getent group "$EXPECTED_GROUP" >/dev/null 2>&1; then
        newgroup="$EXPECTED_GROUP"
    elif getent group "0" >/dev/null 2>&1; then
        # Fallback to GID 0 if the 'root' name isn't found
        newgroup="0"
    fi

    if [[ -z "$newgroup" ]]; then
        >&2 echo "ERROR|Group '$EXPECTED_GROUP' (GID 0) is not a defined group on the system. Cannot apply chgrp."
    else
        # Check if the current group owner is not the expected group owner (GID 0)
        CURRENT_GID=$(stat -c "%g" "$TARGET_FILE")
        if [ "$CURRENT_GID" != "0" ]; then
            echo "    -> Changing group owner of $TARGET_FILE to $newgroup."
            chgrp --no-dereference "$newgroup" "$TARGET_FILE"
            echo "[+] Remediation complete. Group owner set to $newgroup."
        else
            echo "    -> Group owner of $TARGET_FILE is already root (GID 0). No action required."
        fi
    fi

else
    echo "WARN|SSHD configuration file ($TARGET_FILE) not found. Skipping group owner fix."
fi

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
