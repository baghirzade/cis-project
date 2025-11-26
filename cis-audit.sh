#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKS_DIR="$BASE_DIR/checks"
REPORTS_DIR="$BASE_DIR/reports"
SKIP_FILE="$BASE_DIR/config/skip-controls.conf"

mkdir -p "$REPORTS_DIR"

DATE=$(date +"%Y%m%d-%H%M%S")
LOGFILE="$REPORTS_DIR/cis-audit-$DATE.log"
export LOGFILE

# common.sh yüklə
# shellcheck source=/dev/null
. "$BASE_DIR/lib/common.sh"

HOSTNAME=$(hostname)

CONTROLS_OK=0
CONTROLS_WARN=0
CONTROLS_FAIL=0
CONTROLS_SKIPPED=0

should_skip() {
    local script_name="$1"
    [[ -f "$SKIP_FILE" ]] && grep -qx "$script_name" "$SKIP_FILE"
}

log_info "Starting CIS-like audit on $HOSTNAME"
log_info "Using log file: $LOGFILE"

for script in "$CHECKS_DIR"/*.sh; do
    [[ -e "$script" ]] || continue
    name=$(basename "$script")

    if should_skip "$name"; then
        log_info "SKIPPED: $name (listed in $SKIP_FILE)"
        ((CONTROLS_SKIPPED++))
        continue
    fi

    log_info "Running check: $name"
    if bash "$script"; then
        ((CONTROLS_OK++))
    else
        # Konvensiya: exit 1 = WARN, exit 2+ = FAIL
        rc=$?
        if [[ $rc -eq 1 ]]; then
            ((CONTROLS_WARN++))
        else
            ((CONTROLS_FAIL++))
        fi
    fi
done

log_info "CIS audit finished, writing summary"

{
    echo
    echo "=== CIS Audit Summary ==="
    echo "Host: $HOSTNAME"
    echo "Report file: $LOGFILE"
    echo
    echo "Control-level totals:"
    echo "  CONTROLS OK       : $CONTROLS_OK"
    echo "  CONTROLS WARN     : $CONTROLS_WARN"
    echo "  CONTROLS FAIL     : $CONTROLS_FAIL"
    echo "  CONTROLS SKIPPED  : $CONTROLS_SKIPPED"
    echo
    echo "--- WARN / FAIL Details (by line) ---"
    grep " [WARN]" "$LOGFILE" || true
    grep " [FAIL]" "$LOGFILE" || true
    echo
    echo "End of report."
} | tee -a "$LOGFILE"

# Exit kodu
if [[ $CONTROLS_FAIL -gt 0 ]]; then
    exit 2
elif [[ $CONTROLS_WARN -gt 0 ]]; then
    exit 1
else
    exit 0
fi