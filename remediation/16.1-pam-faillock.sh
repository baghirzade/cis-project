#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-16.1"

FILES=("/etc/pam.d/common-auth" "/etc/pam.d/password-auth" "/etc/pam.d/system-auth")

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  TS="$(date +%Y%m%d-%H%M%S)"
  cp -p "$f" "${f}.cis.${TS}.bak"
  log_info "$CONTROL_ID: Backup created for $f"

  if ! grep -Eq 'pam_faillock.so' "$f" && ! grep -Eq 'pam_tally2.so' "$f"; then
    echo "auth required pam_faillock.so preauth silent deny=5 unlock_time=900" >> "$f"
    echo "auth [default=die] pam_faillock.so authfail deny=5 unlock_time=900" >> "$f"
    echo "account required pam_faillock.so" >> "$f"
    log_ok "$CONTROL_ID: Added basic pam_faillock rules into $f"
  else
    log_info "$CONTROL_ID: $f already contains faillock/tally2 – manual tuning advised"
  fi
done
return 0