#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$BASE_DIR/reports"
REMEDIATION_DIR="$BASE_DIR/remediation"

# shellcheck source=/dev/null
. "$BASE_DIR/lib/common.sh"

ensure_root

LATEST_REPORT="$(ls -1 "$REPORTS_DIR"/cis-audit-*.log 2>/dev/null | sort | tail -n1 || true)"

if [ -z "$LATEST_REPORT" ]; then
    log_error "No audit report found."
    exit 1
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REMEDIATION_LOG="$REPORTS_DIR/cis-remediation-$TIMESTAMP.log"

log_info "Latest audit report: $LATEST_REPORT"
log_info "Remediation log: $REMEDIATION_LOG"
echo

# Collect controls to remediate (WARN + FAIL only)
mapfile -t REMEDIATE_LINES < <(grep -E '^(WARN|FAIL)\|' "$LATEST_REPORT" || true)

if [ "${#REMEDIATE_LINES[@]}" -eq 0 ]; then
    log_info "No controls require remediation."
    exit 0
fi

log_info "Controls to remediate:"
REMEDIATE_IDS=()
for line in "${REMEDIATE_LINES[@]}"; do
    IFS='|' read -r STATUS ID MSG <<< "$line"
    REMEDIATE_IDS+=("$ID")
    echo " - $ID"
done
echo

for id in "${REMEDIATE_IDS[@]}"; do
    FIX_SCRIPT="$REMEDIATION_DIR/$id.sh"

    # Respect skip-controls.conf even at remediation time
    if is_skipped_control "$BASE_DIR" "$id"; then
        echo "[SKIPPED-CONFIG] $id (listed in skip-controls.conf)" >> "$REMEDIATION_LOG"
        continue
    fi

    if [ -x "$FIX_SCRIPT" ]; then
        # Show which rule is being remediated on screen
        echo "[REMEDIATE] $id"

        echo "[RUN] $id" >> "$REMEDIATION_LOG"
        "$FIX_SCRIPT" >> "$REMEDIATION_LOG" 2>&1 || {
            echo "[ERROR] Remediation failed for $id" >> "$REMEDIATION_LOG"
        }
    else
        echo "[MISSING] No remediation script for: $id" >> "$REMEDIATION_LOG"
        echo "[MISSING] $id (no remediation script found)"
    fi
done

echo
log_info "Remediation process finished. See log:"
log_info "$REMEDIATION_LOG"

echo "A system reboot is required to complete the fix process."
echo "Please run audit after reboot."
