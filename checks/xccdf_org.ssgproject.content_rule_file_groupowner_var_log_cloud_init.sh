#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_cloud_init"
TITLE="Ensure /var/log/cloud-init logs have group ownership set to adm or root"

run() {

    TARGET_DIR="/var/log/"
    found_noncompliant=0
    found_files=0

    # Check existence of required groups
    if ! getent group adm >/dev/null && ! getent group root >/dev/null; then
        echo "FAIL|$RULE_ID|Neither 'adm' nor 'root' group exists on system"
        return 0
    fi

    # Find matching log files
    while IFS= read -r file; do
        [[ -f "$file" ]] || continue
        found_files=1

        CURRENT_GID=$(stat -c "%g" "$file")
        CURRENT_GNAME=$(stat -c "%G" "$file")

        # Valid groups: root (gid 0) and adm
        if [[ "$CURRENT_GID" -ne 0 && "$CURRENT_GNAME" != "adm" ]]; then
            echo "FAIL|$RULE_ID|File $file has group '$CURRENT_GNAME' (gid $CURRENT_GID), expected adm or root"
            found_noncompliant=1
        fi
    done < <(find "$TARGET_DIR" -maxdepth 1 -type f -regextype posix-extended -regex '.*cloud-init\.log.*')

    # If no files at all found → FAIL (CIS expects log to exist)
    if [[ $found_files -eq 0 ]]; then
        echo "FAIL|$RULE_ID|No cloud-init log files were found in /var/log/"
        return 0
    fi

    if [[ $found_noncompliant -eq 0 ]]; then
        echo "OK|$RULE_ID|All cloud-init log files have correct group ownership"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi