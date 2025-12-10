#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$BASE_DIR/reports"

# shellcheck source=/dev/null
. "$BASE_DIR/lib/common.sh"

if [ ! -d "$REPORTS_DIR" ]; then
    log_error "Report directory not found: $REPORTS_DIR"
    exit 1
fi

LATEST_REPORT="$(ls -1 "$REPORTS_DIR"/cis-audit-*.log 2>/dev/null | sort | tail -n1 || true)"

if [ -z "$LATEST_REPORT" ]; then
    log_error "No report found ($REPORTS_DIR/cis-audit-*.log)"
    exit 1
fi

log_info "Latest report: $LATEST_REPORT"
echo

OK=0
WARN=0
FAIL=0
SKIPPED=0
NOTAPPL=0
TOTAL=0

printf "%-8s %-60s %s\n" "STATUS" "CONTROL_ID" "MESSAGE"
printf "%0.s-" {1..130}
echo

while IFS='|' read -r STATUS ID MSG; do
    [ -z "$STATUS" ] && continue

    case "$STATUS" in
        OK)      OK=$((OK+1)) ;;
        WARN)    WARN=$((WARN+1)) ;;
        FAIL)    FAIL=$((FAIL+1)) ;;
        SKIPPED) SKIPPED=$((SKIPPED+1)) ;;
        NOTAPPL) NOTAPPL=$((NOTAPPL+1)) ;;
    esac

    TOTAL=$((TOTAL+1))
    printf "%-8s %-60s %s\n" "$STATUS" "$ID" "$MSG"
done < "$LATEST_REPORT"

echo
echo "====================================="
echo "TOTAL    = $TOTAL"
echo "OK       = $OK"
echo "WARN     = $WARN"
echo "FAIL     = $FAIL"
echo "SKIPPED  = $SKIPPED"
echo "NOTAPPL  = $NOTAPPL"
echo "====================================="
