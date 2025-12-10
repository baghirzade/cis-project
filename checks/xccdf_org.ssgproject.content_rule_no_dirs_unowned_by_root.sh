#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_dirs_unowned_by_root"

run() {

    IFS=':' read -ra PATH_DIRS <<< "$PATH"

    bad=()

    for dir in "${PATH_DIRS[@]}"; do
        [[ -z "$dir" ]] && continue

        # Skip non-absolute paths
        [[ "$dir" != /* ]] && bad+=("$dir(non-absolute)") && continue

        # Does not exist
        [[ ! -e "$dir" ]] && bad+=("$dir(missing)") && continue

        # Must be a directory
        [[ ! -d "$dir" ]] && bad+=("$dir(not-a-dir)") && continue

        # Must be owned by root
        owner=$(stat -c "%u" "$dir" 2>/dev/null)
        [[ "$owner" != "0" ]] && bad+=("$dir(uid=$owner)") && continue
    done

    # No violations → OK
    if [[ ${#bad[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|All PATH directories are owned by root"
        return 0
    fi

    # Build single line result
    list=$(printf "%s " "${bad[@]}")

    echo "WARN|$RULE_ID|Non-root or invalid PATH entries: $list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi