#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_grub2_cfg"
TITLE="/boot/grub/grub.cfg must be owned by root (uid 0)"

run() {

    # Not applicable inside containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Running inside a container"
        return 0
    fi

    # Rule applies only when grub2-common AND linux-base are installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' grub2-common 2>/dev/null | grep -q installed \
       || ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|Required packages grub2-common and linux-base not installed"
        return 0
    fi

    CFG="/boot/grub/grub.cfg"

    if [[ ! -f "$CFG" ]]; then
        echo "WARN|$RULE_ID|$CFG does not exist"
        return 0
    fi

    OWNER_UID=$(stat -c "%u" "$CFG" 2>/dev/null || echo "")

    if [[ "$OWNER_UID" == "0" ]]; then
        echo "OK|$RULE_ID|$CFG is correctly owned by root (uid 0)"
    else
        echo "WARN|$RULE_ID|$CFG is owned by uid $OWNER_UID, expected 0"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi