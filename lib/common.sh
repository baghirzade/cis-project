#!/usr/bin/env bash
<<<<<<< HEAD
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
=======

# Color helper
_color() {
    local code="$1"; shift
    if [ -t 1 ]; then
        printf "\033[%sm%s\033[0m" "$code" "$*"
    else
        printf "%s" "$*"
    fi
}

log_info()  { echo "$(_color '32;1' '[INFO]')  $*"; }
log_warn()  { echo "$(_color '33;1' '[WARN]')  $*"; }
log_error() { echo "$(_color '31;1' '[ERROR]') $*" >&2; }

ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
}

# Return first non-empty line from stdin
first_non_empty_line() {
    sed -n '/./{p;q}' 2>/dev/null
}

# Skip-controls.conf: controls that must be skipped by user configuration
is_skipped_control() {
    local base_dir="$1"
    local control_id="$2"
    local cfg="$base_dir/config/skip-controls.conf"

    [ -f "$cfg" ] || return 1

    # Ignore empty and commented lines, match full ID
    if grep -E '^[[:space:]]*'"$control_id"'[[:space:]]*$' "$cfg" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}
>>>>>>> 3a7df70 (Initial commit for v2.0 CIS automation script)
