#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REMEDIATION_DIR="$BASE_DIR/remediation"
REPORTS_DIR="$BASE_DIR/reports"
SKIP_FILE="$BASE_DIR/config/skip-controls.conf"

mkdir -p "$REPORTS_DIR"

DATE=$(date +"%Y%m%d-%H%M%S")
LOGFILE="$REPORTS_DIR/cis-remediate-$DATE.log"
export LOGFILE

# shellcheck source=/dev/null
. "$BASE_DIR/lib/common.sh"

should_skip() {
    local script_name="$1"
    [[ -f "$SKIP_FILE" ]] && grep -qx "$script_name" "$SKIP_FILE"
}

log_info "Starting CIS-like remediation on $(hostname)"
log_info "Using log file: $LOGFILE"

for script in "$REMEDIATION_DIR"/*.sh; do
    [[ -e "$script" ]] || continue
    name=$(basename "$script")

    if should_skip "$name"; then
        log_info "SKIPPED remediation: $name (listed in $SKIP_FILE)"
        continue
    fi

    log_info "Running remediation: $name"
    if ! bash "$script"; then
        log_warn "Remediation script $name returned non-zero exit code"
    fi
done

log_ok "Remediation completed"