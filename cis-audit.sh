#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKS_DIR="$BASE_DIR/checks"
REPORTS_DIR="$BASE_DIR/reports"
<<<<<<< HEAD
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
=======

# shellcheck source=/dev/null
. "$BASE_DIR/lib/common.sh"

ensure_root
mkdir -p "$REPORTS_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$REPORTS_DIR/cis-audit-$TIMESTAMP.log"

OK=0
WARN=0
FAIL=0
SKIPPED=0
NOTAPPL=0
TOTAL=0

log_info "Checks directory: $CHECKS_DIR"
log_info "Report file     : $REPORT_FILE"
echo

echo "--- Starting Evaluation ---"
echo

for script in "$CHECKS_DIR"/*.sh; do
    [ -e "$script" ] || continue
    [ -x "$script" ] || chmod +x "$script"

    name="$(basename "$script")"
    control_id="${name%.sh}"

    # User skip config
    if is_skipped_control "$BASE_DIR" "$control_id"; then
        STATUS="SKIPPED"
        ID="$control_id"
        MSG="Skipped via config/skip-controls.conf"

        SKIPPED=$((SKIPPED+1))
        TOTAL=$((TOTAL+1))

        echo "$STATUS|$ID|$MSG" >> "$REPORT_FILE"

        echo "Title   $MSG"
        echo "Rule    $ID"
        echo "Result  notchecked"
        echo
        continue
    fi

    # Run check script
    output="$("$script" 2>&1 || true)"
    line="$(printf '%s\n' "$output" | first_non_empty_line)"

    if [ -z "$line" ]; then
        STATUS="FAIL"
        ID="$control_id"
        MSG="No output from check script"
    else
        IFS='|' read -r STATUS ID MSG <<< "$line"
        STATUS="${STATUS:-WARN}"
        ID="${ID:-$control_id}"
        MSG="${MSG:-no message}"
    fi

    # NEW: Proper SCAP-style RESULT mapping
    case "$STATUS" in
        OK)
            OK=$((OK+1))
            RESULT="pass"
            ;;
        WARN)
            WARN=$((WARN+1))
            RESULT="warn"
            ;;
        FAIL)
            FAIL=$((FAIL+1))
            RESULT="fail"
            ;;
        SKIPPED)
            SKIPPED=$((SKIPPED+1))
            RESULT="notchecked"
            ;;
        NOTAPPL)
            NOTAPPL=$((NOTAPPL+1))
            RESULT="notapplicable"
            ;;
        *)
            STATUS="FAIL"
            FAIL=$((FAIL+1))
            RESULT="fail"
            ;;
    esac

    TOTAL=$((TOTAL+1))

    # Log file output
    echo "$STATUS|$ID|$MSG" >> "$REPORT_FILE"
    # Color output
    GREEN="\e[32m"
    YELLOW="\e[33m"
    RED="\e[31m"
    CYAN="\e[36m"
    GREY="\e[90m"
    RESET="\e[0m"

    case "$RESULT" in
        pass)
            COLOR="$GREEN"
            ;;
        warn)
            COLOR="$YELLOW"
            ;;
        fail)
            COLOR="$RED"
            ;;
        notchecked)
            COLOR="$CYAN"
            ;;
        notapplicable)
            COLOR="$GREY"
            ;;
        *)
            COLOR="$RESET"
            ;;
    esac

    echo -e "Title   $MSG"
    echo -e "Rule    $ID"
    echo -e "Result  ${COLOR}${RESULT}${RESET}"
    echo

    # Human-readable SCAP-like output
    # echo "Title   $MSG"
    # echo "Rule    $ID"
    # echo "Result  $RESULT"
    # echo
done

echo "====================================="
echo "TOTAL    = $TOTAL"
echo "OK       = $OK"
echo "WARN     = $WARN"
echo "FAIL     = $FAIL"
echo "SKIPPED  = $SKIPPED"
echo "NOTAPPL  = $NOTAPPL"
echo "====================================="
echo

log_info "Report file: $REPORT_FILE"
>>>>>>> 3a7df70 (Initial commit for v2.0 CIS automation script)
