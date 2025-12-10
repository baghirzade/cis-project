#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_nftables_ensure_default_deny_policy"
TITLE="Ensure nftables default deny policy is set (DROP)"

run() {

    # nftables must be installed
    if ! command -v nft >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|nft command not found (nftables not installed)"
        return 0
    fi

    # check table inet filter chains and default policy
    NFT_OUTPUT=$(nft list ruleset 2>/dev/null)

    # Expected policy “drop”
    for chain in input forward output; do
        if ! echo "$NFT_OUTPUT" | grep -E "chain ${chain} .* policy drop" >/dev/null; then
            echo "WARN|$RULE_ID|Default policy for $chain is NOT drop"
            return 0
        fi
    done

    echo "OK|$RULE_ID|All nftables default policies are set to DROP"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
