#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_sshd_config"

echo "[*] Applying remediation for: $RULE_ID (Ensure SSHD configuration file owner is root)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

TARGET_FILE="/etc/ssh/sshd_config"
EXPECTED_OWNER="root"

if [ -f "$TARGET_FILE" ]; then

    newown=""
    # Check if UID 0 (root) is a defined user
    if id "$EXPECTED_OWNER" >/dev/null 2>&1; then
        newown="$EXPECTED_OWNER"
    elif id "0" >/dev/null 2>&1; then
        # Fallback to UID 0 if the 'root' name isn't found for some reason, though unlikely
        newown="0"
    fi

    if [[ -z "$newown" ]]; then
        >&2 echo "ERROR|User '$EXPECTED_OWNER' (UID 0) is not a defined user on the system. Cannot apply chown."
    else
        # Check if the current owner is not the expected owner (UID 0)
        CURRENT_UID=$(stat -c "%u" "$TARGET_FILE")
        if [ "$CURRENT_UID" != "0" ]; then
            echo "    -> Changing owner of $TARGET_FILE to $newown."
            chown --no-dereference "$newown" "$TARGET_FILE"
            echo "[+] Remediation complete. Owner set to $newown."
        else
            echo "    -> Owner of $TARGET_FILE is already root (UID 0). No action required."
        fi
    fi

else
    echo "WARN|SSHD configuration file ($TARGET_FILE) not found. Skipping owner fix."
fi

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
