#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_kernel_yama_ptrace_scope"

run() {

    # Check runtime value
    val=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null)

    if [[ "$val" == "1" ]]; then
        echo "OK|$RULE_ID|kernel.yama.ptrace_scope is correctly set to 1"
        exit 0
    else
        echo "FAIL|$RULE_ID|kernel.yama.ptrace_scope is $val (expected 1)"
        exit 1
    fi
}

run
