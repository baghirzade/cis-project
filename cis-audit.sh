#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKS_DIR="$BASE_DIR/checks"
REPORTS_DIR="$BASE_DIR/reports"

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