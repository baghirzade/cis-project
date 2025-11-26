#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-8.2"

AUDIT_RULES_MAIN="/etc/audit/rules.d"
AUDITCTL_BIN="$(command -v auditctl || true)"

have_regex() {
  local regex="$1" file
  for file in "$AUDIT_RULES_MAIN"/*.rules; do
    [[ -f "$file" ]] || continue
    if grep -Eq "$regex" "$file"; then
      return 0
    fi
  done
  return 1
}

check_audit_rules_files() {
  local missing=0
  log_info "$CONTROL_ID: Checking static audit rules in $AUDIT_RULES_MAIN"

  local patterns=(
    '/etc/passwd'
    '/etc/shadow'
    '/etc/group'
    '/etc/gshadow'
    '/etc/sudoers'
    '/etc/sudoers\.d/'
    '/var/log/sudo\.log'
  )

  local p
  for p in "${patterns[@]}"; do
    local re="-w[[:space:]]+${p}[[:space:]]+-p[[:space:]]+wa"
    if have_regex "$re"; then
      log_ok "$CONTROL_ID: Rule for ${p} changes present in disk rules"
    else
      log_warn "$CONTROL_ID: Rule for ${p} changes is MISSING in disk rules"
      missing=1
    fi
  done

  if have_regex '-a[[:space:]]+always,exit[[:space:]]+-F[[:space:]]+arch=b64[[:space:]]+-S[[:space:]]+execve'; then
    log_ok "$CONTROL_ID: execve syscall audit rule (64-bit) present in disk rules"
  else
    log_warn "$CONTROL_ID: execve syscall audit rule (64-bit) MISSING in disk rules"
    missing=1
  fi

  if have_regex '-a[[:space:]]+always,exit[[:space:]]+-F[[:space:]]+arch=b32[[:space:]]+-S[[:space:]]+execve'; then
    log_ok "$CONTROL_ID: execve syscall audit rule (32-bit) present in disk rules"
  else
    log_warn "$CONTROL_ID: execve syscall audit rule (32-bit) MISSING in disk rules"
    missing=1
  fi

  return "$missing"
}

check_loaded_audit_rules() {
  [[ -z "$AUDITCTL_BIN" ]] && {
    log_warn "$CONTROL_ID: auditctl not found – cannot validate loaded rules"
    return 1
  }

  local out
  out=$("$AUDITCTL_BIN" -l 2>/dev/null || true)

  local patterns=(
    '/etc/passwd'
    '/etc/shadow'
    '/etc/group'
    '/etc/gshadow'
    '/etc/sudoers'
    '/etc/sudoers.d/'
    '/var/log/sudo.log'
  )

  local p found
  for p in "${patterns[@]}"; do
    if grep -q "$p" <<<"$out"; then
      log_ok "$CONTROL_ID: Loaded rule for $p changes is present (pattern: $p)"
    else
      log_warn "$CONTROL_ID: Loaded rule for $p changes is MISSING (pattern: $p)"
    fi
  done

  if grep -q 'arch=b64' <<<"$out"; then
    log_ok "$CONTROL_ID: Loaded rule for execve syscall (64-bit arch rule present) is present (pattern: arch=b64)"
  else
    log_warn "$CONTROL_ID: Loaded rule for execve syscall (64-bit arch) is MISSING"
  fi

  if grep -q 'arch=b32' <<<"$out"; then
    log_ok "$CONTROL_ID: Loaded rule for execve syscall (32-bit arch rule present) is present (pattern: arch=b32)"
  else
    log_warn "$CONTROL_ID: Loaded rule for execve syscall (32-bit arch) is MISSING"
  fi

  if grep -q ' -S execve' <<<"$out"; then
    log_ok "$CONTROL_ID: Loaded rule for execve syscall (-S execve present) is present (pattern:  -S execve)"
  else
    log_warn "$CONTROL_ID: Loaded rule for execve syscall (-S execve) is MISSING"
  fi
}

check_audit_rules_basic() {
  check_audit_rules_files
  check_loaded_audit_rules
}

check_audit_rules_basic
