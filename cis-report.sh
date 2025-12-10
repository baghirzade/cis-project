#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$BASE_DIR/reports"

<<<<<<< HEAD
latest_log=$(ls -1t "$REPORTS_DIR"/cis-audit-*.log 2>/dev/null | head -n1 || true)

if [[ -z "$latest_log" ]]; then
    echo "No cis-audit-*.log files found in $REPORTS_DIR"
    exit 1
fi

echo "=== CIS Audit Summary ==="
echo "Host: $(hostname)"
echo "Report file: $latest_log"
echo

CONTROLS_OK=$(grep -E "Control-level totals:" -A4 "$latest_log" | grep "CONTROLS OK" | awk '{print $4}')
CONTROLS_WARN=$(grep -E "Control-level totals:" -A4 "$latest_log" | grep "CONTROLS WARN" | awk '{print $4}')
CONTROLS_FAIL=$(grep -E "Control-level totals:" -A4 "$latest_log" | grep "CONTROLS FAIL" | awk '{print $4}')
CONTROLS_SKIP=$(grep -E "Control-level totals:" -A4 "$latest_log" | grep "CONTROLS SKIPPED" | awk '{print $4}')

echo "Control-level totals:"
echo "  CONTROLS OK       : ${CONTROLS_OK:-0}"
echo "  CONTROLS WARN     : ${CONTROLS_WARN:-0}"
echo "  CONTROLS FAIL     : ${CONTROLS_FAIL:-0}"
echo "  CONTROLS SKIPPED  : ${CONTROLS_SKIP:-0}"
echo

echo "--- WARN / FAIL Details ---"
grep " [WARN]" "$latest_log" || echo "No WARN entries."
grep " [FAIL]" "$latest_log" || echo "No FAIL entries."
echo
echo "End of report."
=======
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
>>>>>>> 3a7df70 (Initial commit for v2.0 CIS automation script)
