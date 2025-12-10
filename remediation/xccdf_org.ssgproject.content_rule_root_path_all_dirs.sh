#!/bin/bash
# REMEDIATION: xccdf_org.ssgproject.content_rule_root_path_all_dirs
# Fix: Build a sanitized PATH containing only existing directories
#      and persist it for root in /root/.profile

if [ "$(id -u)" -ne 0 ]; then
    echo "This remediation must be run as root!" >&2
    exit 1
fi

ORIGINAL_PATH="${PATH}"
IFS=':' read -ra PATH_DIRS <<< "$ORIGINAL_PATH"

SANITIZED_PATH=""

for dir in "${PATH_DIRS[@]}"; do
    # Skip empty entries
    [ -z "$dir" ] && {
        echo "Removing empty PATH entry (':')."
        continue
    }

    # Only consider existing directories
    if [ -d "$dir" ]; then
        # Build new PATH string
        if [ -z "$SANITIZED_PATH" ]; then
            SANITIZED_PATH="$dir"
        else
            SANITIZED_PATH="${SANITIZED_PATH}:$dir"
        fi
    else
        echo "Removing invalid PATH entry '$dir' (does not exist or not a directory)."
    fi
done

echo "Old PATH: $ORIGINAL_PATH"
echo "New PATH: $SANITIZED_PATH"

# Apply for current session
export PATH="$SANITIZED_PATH"

# Persist for future root logins in /root/.profile
PROFILE_FILE="/root/.profile"

# Backup if exists
if [ -f "$PROFILE_FILE" ]; then
    cp "$PROFILE_FILE" "${PROFILE_FILE}.bak.$(date +%Y%m%d%H%M%S)"
fi

touch "$PROFILE_FILE"

# Remove any existing PATH= line we previously may have added
sed -i '/^PATH=.*$/d' "$PROFILE_FILE"
sed -i '/^export PATH$/d' "$PROFILE_FILE"

{
    echo ""
    echo "# CIS: root PATH cleaned to contain only existing directories"
    echo "PATH=\"$SANITIZED_PATH\""
    echo "export PATH"
} >> "$PROFILE_FILE"

echo "Remediation completed. New PATH persisted in $PROFILE_FILE"
