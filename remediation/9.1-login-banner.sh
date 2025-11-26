#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-9.1"

FILES=("/etc/motd" "/etc/issue" "/etc/issue.net")

for f in "${FILES[@]}"; do
  TS="$(date +%Y%m%d-%H%M%S)"
  [[ -f "$f" ]] && cp -p "$f" "${f}.cis.${TS}.bak"
  echo "Authorized uses only. All activity may be monitored and reported." > "$f"
  chown root:root "$f"
  chmod 644 "$f"
  log_ok "$CONTROL_ID: Banner set and permissions fixed for $f"
done
return 0