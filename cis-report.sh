#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$BASE_DIR/reports"

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