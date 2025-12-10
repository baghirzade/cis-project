#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_chronyd_run_as_chrony_user"

echo "[*] Applying remediation for: $RULE_ID"

# Applicability
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] Non-Debian system, skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q installed; then
    echo "[!] linux-base not installed, skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' chrony \
    2>/dev/null | grep -q installed; then
    echo "[!] chrony package not installed, skipping."
    exit 0
fi

config="/etc/chrony/chrony.conf"

# Ensure config file exists
touch "$config"

# Strip undesired characters from the key (same as SCAP logic)
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^user")
formatted_output="$stripped_key _chrony"

# If a "user ..." entry exists, replace it; else append at end
if grep -qiE "^user\>" "$config"; then
    # Replace existing user directive
    escaped_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    sed -i --follow-symlinks "s/^user\\>.*/$escaped_output/I" "$config"
else
    # Ensure newline at EOF if missing
    if [[ -s "$config" ]] && [[ -n "$(tail -c 1 -- "$config" || true)" ]]; then
        sed -i --follow-symlinks '$a\' "$config"
    fi
    echo "$formatted_output" >> "$config"
fi

echo "[+] chronyd now configured to run as user _chrony"
