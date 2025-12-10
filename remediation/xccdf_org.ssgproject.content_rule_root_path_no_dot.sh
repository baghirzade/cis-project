#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_root_path_no_dot"
TITLE="Root PATH must not contain '.' (current directory)"

if [ "$(id -u)" -ne 0 ]; then
    echo "This remediation must be run as root!" >&2
    exit 1
fi

ORIGINAL_PATH="${PATH}"
IFS=':' read -ra PATH_PARTS <<< "$ORIGINAL_PATH"

SANITIZED_PATH=""

for part in "${PATH_PARTS[@]}"; do
    # Skip empty elements (which act as current directory)
    if [ -z "$part" ]; then
        echo "Removing empty PATH element (interpreted as current directory '.')."
        continue
    fi

    # Skip explicit '.' entries
    if [ "$part" = "." ]; then
        echo "Removing explicit '.' from PATH."
        continue
    fi

    # Rebuild sanitized PATH
    if [ -z "$SANITIZED_PATH" ]; then
        SANITIZED_PATH="$part"
    else
        SANITIZED_PATH="${SANITIZED_PATH}:$part"
    fi
done

echo "Old PATH: $ORIGINAL_PATH"
echo "New PATH: $SANITIZED_PATH"

# Apply for current shell
export PATH="$SANITIZED_PATH"

# Persist for future root logins in /root/.profile
PROFILE_FILE="/root/.profile"

# Backup existing profile if present
if [ -f "$PROFILE_FILE" ]; then
    cp "$PROFILE_FILE" "${PROFILE_FILE}.bak.$(date +%Y%m%d%H%M%S)"
fi

touch "$PROFILE_FILE"

# Remove existing PATH lines we might conflict with
sed -i '/^PATH=.*$/d' "$PROFILE_FILE"
sed -i '/^export PATH$/d' "$PROFILE_FILE"

{
    echo ""
    echo "# CIS: root PATH cleaned to remove '.' and empty elements"
    echo "PATH=\"$SANITIZED_PATH\""
    echo "export PATH"
} >> "$PROFILE_FILE"

echo "Remediation completed. New PATH persisted in $PROFILE_FILE"
