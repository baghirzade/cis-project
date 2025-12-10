#!/usr/bin/env bash
# Check that password last change date is not in the future and is valid

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_last_change_is_in_past"

# Basic sanity check
if [[ ! -r /etc/shadow ]]; then
    echo "FAIL|${RULE_ID}|/etc/shadow is not readable"
    exit 1
fi

# Today in days since epoch
TODAY_DAYS=$(( $(date +%s) / 86400 ))

PROBLEM_USERS=()

while IFS=: read -r USER PASS LASTCHG REST; do
    # Only consider accounts with a real hash (starts with '$')
    [[ -z "$USER" ]] && continue
    [[ "$PASS" =~ ^\$ ]] || continue

    # Empty or non-numeric last change
    if [[ -z "$LASTCHG" || ! "$LASTCHG" =~ ^[0-9]+$ ]]; then
        PROBLEM_USERS+=("$USER")
        continue
    fi

    # Last change date in the future
    if (( LASTCHG > TODAY_DAYS )); then
        PROBLEM_USERS+=("$USER")
    fi
done < /etc/shadow

if [[ ${#PROBLEM_USERS[@]} -eq 0 ]]; then
    echo "OK|${RULE_ID}|All accounts have a valid password last change date in the past"
else
    # Konfiqurasiya problemi olduğuna görə WARN qaytarırıq, skript xətası deyil
    echo "WARN|${RULE_ID}|Accounts with invalid or future password last change date: ${PROBLEM_USERS[*]}"
fi
