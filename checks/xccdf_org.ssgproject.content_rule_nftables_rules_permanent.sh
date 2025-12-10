#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_nftables_rules_permanent"
TITLE="Ensure nftables permanent rules are configured"

run() {

    # nftables must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' nftables \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables not installed"
        return 0
    fi

    # firewalld must NOT be running
    if systemctl is-active firewalld &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|firewalld active, nftables permanent rules not applicable"
        return 0
    fi

    MASTER_FILE="/etc/nftables.conf"
    FAMILY="inet"
    RULEFILE="/etc/${FAMILY}-filter.rules"

    # Check if rule file exists
    if [[ ! -f "$RULEFILE" ]]; then
        echo "WARN|$RULE_ID|Permanent rules file '$RULEFILE' does not exist"
        return 0
    fi

    # Check include directive in /etc/nftables.conf
    if ! grep -qxF "include \"/etc/${FAMILY}-filter.rules\"" "$MASTER_FILE" 2>/dev/null; then
        echo "WARN|$RULE_ID|Include directive missing in $MASTER_FILE"
        return 0
    fi

    echo "OK|$RULE_ID|Permanent nftables rules and include directive are correctly configured"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
