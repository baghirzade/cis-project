#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_nftables_base_chain"
TITLE="Ensure required nftables base chains are present"

run() {
    # Check platform applicability
    if ! command -v nft >/dev/null 2>&1 || ! dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables package is not installed."
        return 0
    fi

    local var_nftables_table='filter'
    local var_nftables_family='inet'
    
    # Expected chains and their required properties
    # Expected structure: chain_name:hook:type:policy
    local -a EXPECTED_CHAINS=(
        "input:input:filter:accept"
        "forward:forward:filter:accept"
        "output:output:filter:accept"
    )
    
    # 1. Check if the base table exists
    if ! nft list tables | grep -q "$var_nftables_family $var_nftables_table"; then
        echo "WARN|$RULE_ID|Table '$var_nftables_family $var_nftables_table' does not exist."
        return 1
    fi

    local TABLE_CONTENT
    TABLE_CONTENT=$(nft list table "$var_nftables_family" "$var_nftables_table" 2>/dev/null)
    
    local RETURN_CODE=0
    
    for entry in "${EXPECTED_CHAINS[@]}"; do
        IFS=":" read -r name hook type policy <<< "$entry"
        
        # Pattern to match the chain definition, ignoring priority as it can vary, but ensuring hook, type, and policy
        # Example pattern: chain input { type filter hook input priority 0 ; policy accept ; }
        local PATTERN="chain $name { type $type hook $hook.*policy $policy ; }"
        
        if ! grep -Pq "$PATTERN" <<< "$TABLE_CONTENT"; then
            echo "WARN|$RULE_ID|Missing or incorrectly configured chain: $name (Expected: type $type, hook $hook, policy $policy)"
            RETURN_CODE=1
        fi
    done
    
    if [ "$RETURN_CODE" -eq 0 ]; then
        echo "OK|$RULE_ID|Required base chains (input, forward, output) are correctly configured in $var_nftables_family $var_nftables_table."
    fi

    return $RETURN_CODE
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
