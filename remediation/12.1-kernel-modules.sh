#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-12.1"

CONF="/etc/modprobe.d/cis-hardening.conf"
TS="$(date +%Y%m%d-%H%M%S)"
[[ -f "$CONF" ]] && cp -p "$CONF" "${CONF}.cis.${TS}.bak"

cat > "$CONF" <<'EOF'
# CIS example: disable potentially unused filesystem modules
install cramfs /bin/true
install squashfs /bin/true
install udf /bin/true
EOF

log_ok "$CONTROL_ID: Created $CONF to disable cramfs/squashfs/udf (install /bin/true)"
return 0