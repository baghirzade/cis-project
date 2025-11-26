#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$BASE_DIR/reports"
mkdir -p "$REPORTS_DIR"

LOGFILE="${LOGFILE:-}"

_ts() {
    date "+%Y-%m-%d %H:%M:%S"
}

_log_raw() {
    local level="$1"; shift
    local msg="$*"
    if [[ -n "$LOGFILE" ]]; then
        echo "$(_ts) [$level]  $msg" | tee -a "$LOGFILE"
    else
        echo "$(_ts) [$level]  $msg"
    fi
}

log_info() { _log_raw "INFO" "$*"; }
log_warn() { _log_raw "WARN" "$*"; }
log_ok()   { _log_raw "OK  " "$*"; }
log_fail() { _log_raw "FAIL" "$*"; }

# Helper: run a command and log on error
run_or_warn() {
    local desc="$1"; shift
    if "$@"; then
        log_ok "$desc"
    else
        log_warn "$desc FAILED: command returned non-zero"
        return 1
    fi
}