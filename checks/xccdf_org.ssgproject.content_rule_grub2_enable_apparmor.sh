#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_grub2_enable_apparmor"

run() {

    # Not applicable inside containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    GRUB_DEFAULT="/etc/default/grub"

    if [[ ! -f "$GRUB_DEFAULT" ]]; then
        echo "WARN|$RULE_ID|/etc/default/grub not found"
        return 0
    fi

    # Extract GRUB_CMDLINE_LINUX content
    CMDLINE=$(grep -E '^\s*GRUB_CMDLINE_LINUX=' "$GRUB_DEFAULT" 2>/dev/null \
                | sed -E 's/^[^"]*"(.*)".*$/\1/')

    if [[ -z "$CMDLINE" ]]; then
        echo "WARN|$RULE_ID|GRUB_CMDLINE_LINUX is missing or empty"
        return 1
    fi

    # Check for required parameters
    if echo "$CMDLINE" | grep -qE '(^|[[:space:]])apparmor=1([[:space:]]|$)' \
       && echo "$CMDLINE" | grep -qE '(^|[[:space:]])security=apparmor([[:space:]]|$)'; then
        echo "OK|$RULE_ID|AppArmor parameters correctly set in GRUB_CMDLINE_LINUX"
        return 0
    fi

    echo "WARN|$RULE_ID|Missing required GRUB parameters: apparmor=1 security=apparmor"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi