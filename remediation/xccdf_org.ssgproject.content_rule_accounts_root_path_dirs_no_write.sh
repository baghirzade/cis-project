#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_root_path_dirs_no_write"

# Remediation yalnız linux-base paketi olan sistemlər üçün
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation is not applicable, 'linux-base' is not installed"
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    >&2 echo "Remediation must be run as root"
    exit 1
fi

>&2 echo "Remediating rule: ${RULE_ID}"

PATH_VALUE="${PATH:-}"

if [ -z "$PATH_VALUE" ]; then
    >&2 echo "Root PATH is empty, nothing to remediate"
    exit 0
fi

IFS=':' read -r -a PATH_DIRS <<< "$PATH_VALUE"

for dir in "${PATH_DIRS[@]}"; do
    [ -z "$dir" ] && continue

    # yalnız absolute path-ləri emal et
    if [[ "$dir" != /* ]]; then
        >&2 echo "Skipping non-absolute PATH entry: '$dir'"
        continue
    fi

    if [ ! -d "$dir" ]; then
        >&2 echo "Skipping missing PATH directory: '$dir'"
        continue
    fi

    # root sahibi edilməlidir
    current_owner=$(stat -Lc '%U' "$dir" 2>/dev/null || echo "?")
    if [ "$current_owner" != "root" ]; then
        >&2 echo "Fixing owner to root for: $dir (was $current_owner)"
        chown root:root "$dir"
    fi

    # group / others write icazəsini götür
    if find "$dir" -maxdepth 0 -perm /022 -type d ! -lname '*' >/dev/null 2>&1; then
        current_perm=$(stat -Lc '%A' "$dir" 2>/dev/null || echo "?")
        >&2 echo "Removing group/others write from: $dir (was $current_perm)"
        chmod go-w "$dir"
    fi
done

exit 0
