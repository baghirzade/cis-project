#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_root_path_no_dot"
TITLE="Root PATH must not contain '.' (current directory)"

run() {
    CURRENT_PATH="${PATH}"
    status=0

    # Check for explicit '.' entry
    if echo ":${CURRENT_PATH}:" | grep -q ':\.:'; then
        echo "FAIL|$RULE_ID|PATH contains explicit '.' element"
        status=1
    fi

    # Check for empty PATH entries: leading ':', trailing ':', or '::'
    if echo "${CURRENT_PATH}" | grep -qE '(^:|::|:$)'; then
        echo "FAIL|$RULE_ID|PATH contains empty element(s) implying current directory"
        status=1
    fi

    if [ "$status" -eq 0 ]; then
        echo "OK|$RULE_ID|PATH does not contain '.' or empty elements"
    fi

    return "$status"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi