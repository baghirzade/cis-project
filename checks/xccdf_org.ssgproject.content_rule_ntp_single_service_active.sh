#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_ntp_single_service_active"

run() {

    # systemd required
    if ! command -v systemctl >/dev/null; then
        echo "NOTAPPL|$RULE_ID|systemctl not found on system"
        return 0
    fi

    SYSTEMCTL_EXEC="/usr/bin/systemctl"
    failures=()

    # Services that MUST be disabled/masked
    SERVICES_TO_DISABLE=("ntp.service" "chrony.service")

    for svc in "${SERVICES_TO_DISABLE[@]}"; do
        if $SYSTEMCTL_EXEC -q list-unit-files "$svc" >/dev/null 2>&1; then

            enabled_state=$($SYSTEMCTL_EXEC is-enabled "$svc" >/dev/null 2>&1 && \
                            $SYSTEMCTL_EXEC is-enabled "$svc" 2>/dev/null || echo "not-found")

            active_state=$($SYSTEMCTL_EXEC is-active "$svc" >/dev/null 2>&1 && \
                           $SYSTEMCTL_EXEC is-active "$svc" 2>/dev/null || echo "inactive")

            # Should be: masked AND inactive
            if [[ "$enabled_state" != "masked" || "$active_state" != "inactive" ]]; then
                failures+=("$svc(enabled=$enabled_state,active=$active_state)")
            fi
        fi
    done

    # Required active service
    ACTIVE_SERVICE="systemd-timesyncd.service"

    if $SYSTEMCTL_EXEC -q list-unit-files "$ACTIVE_SERVICE" >/dev/null 2>&1; then
        active_state=$($SYSTEMCTL_EXEC is-active "$ACTIVE_SERVICE" >/dev/null 2>&1 && \
                       $SYSTEMCTL_EXEC is-active "$ACTIVE_SERVICE" 2>/dev/null || echo "inactive")

        if [[ "$active_state" != "active" ]]; then
            failures+=("$ACTIVE_SERVICE(active=$active_state)")
        fi
    else
        failures+=("$ACTIVE_SERVICE(not-found)")
    fi

    # Final decision
    if [[ ${#failures[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|systemd-timesyncd is active, all other NTP services disabled"
        return 0
    fi

    list=$(printf "%s " "${failures[@]}")
    echo "WARN|$RULE_ID|Non-compliant NTP service states detected: $list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi