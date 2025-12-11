#!/usr/bin/env bash

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
log_success() { echo -e "[\e[32mSUCCESS\e[0m] $1"; }
log_remediate() { echo -e "[\e[33mREMEDIATE\e[0m] $1"; }

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
