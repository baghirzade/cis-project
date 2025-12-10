#!/bin/bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_root"
TITLE="Root shell init files must set umask to 0027"

# If bash is not installed → not applicable
if ! dpkg-query --show --showformat='${db:Status-Status}' bash 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|$RULE_ID|bash package not installed"
    exit 0
fi

REQUIRED_UMASK="0027"
files=("/root/.bashrc" "/root/.profile")

found_any=0
bad=0

for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue

    while IFS= read -r line; do
        found_any=1

        val=$(awk '{for (i=1;i<=NF;i++) if ($i=="umask") {print $(i+1); exit}}' <<< "$line")

        if [[ "$val" != "$REQUIRED_UMASK" ]]; then
            echo "WARN|$RULE_ID|$file has umask $val (expected $REQUIRED_UMASK)"
            bad=1
        fi

    done < <(grep -E '^[[:space:]]*umask[[:space:]]+[0-7]{3}' "$file" 2>/dev/null)
done

# If neither file had any umask setting at all
if [[ "$found_any" -eq 0 ]]; then
    echo "WARN|$RULE_ID|No umask setting found in /root/.bashrc or /root/.profile"
    exit 1
fi

if [[ "$bad" -eq 0 ]]; then
    echo "OK|$RULE_ID|Root umask is correctly set to $REQUIRED_UMASK"
    exit 0
else
    exit 1
fi
