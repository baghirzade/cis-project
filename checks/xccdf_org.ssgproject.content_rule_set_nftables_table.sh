#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_nftables_table"
TITLE="Ensure required nftables table is present"

run() {
    # Check platform applicability
    if ! command -v nft >/dev/null 2>&1 || ! dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables package is not installed."
        return 0
    fi

    local var_nftables_family='inet'
    local var_nftables_table='filter'
    local RETURN_CODE=0
    
    # Check if the table exists
    if ! nft list tables | grep -E "^table $var_nftables_family $var_nftables_table( |$)"; then
        echo "WARN|$RULE_ID|Required nftables table '$var_nftables_family $var_nftables_table' is missing."
        RETURN_CODE=1
    else
        echo "OK|$RULE_ID|Required nftables table '$var_nftables_family $var_nftables_table' is present."
        RETURN_CODE=0
    fi

    return $RETURN_CODE
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
