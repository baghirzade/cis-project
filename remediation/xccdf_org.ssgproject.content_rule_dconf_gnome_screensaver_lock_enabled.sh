#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_screensaver_lock_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure GNOME screensaver lock is enabled and locked)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicable only if gdm3 is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] gdm3 is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Prepare dconf profiles
mkdir -p /etc/dconf/profile
USER_PROFILE="/etc/dconf/profile/user"
GDM_PROFILE="/etc/dconf/profile/gdm"

# Configure user profile: user-db:user + system-db:local
: > "$USER_PROFILE"
if ! grep -Pzq "(?s)^\s*user-db:user.*\n\s*system-db:local" "$USER_PROFILE"; then
    sed -i --follow-symlinks "1s/^/user-db:user\nsystem-db:local\n/" "$USER_PROFILE"
fi

# Configure gdm profile: user-db:user + system-db:gdm
: > "$GDM_PROFILE"
if ! grep -Pzq "(?s)^\s*user-db:user.*\n\s*system-db:gdm" "$GDM_PROFILE"; then
    sed -i --follow-symlinks "1s/^/user-db:user\nsystem-db:gdm\n/" "$GDM_PROFILE"
fi

# Ensure dconf db directories exist
DCONF_DB_DIR="/etc/dconf/db"
LOCAL_DIR="$DCONF_DB_DIR/local.d"
GDM_DIR="$DCONF_DB_DIR/gdm.d"
LOCKS_DIR="$LOCAL_DIR/locks"

mkdir -p "$LOCAL_DIR" "$GDM_DIR" "$LOCKS_DIR"

# Permissions and initial dconf update
chmod -R u=rwX,go=rX /etc/dconf/profile
(umask 0022 && dconf update || true)

# -------------------------
# Handle lock for lock-enabled
# -------------------------

# Comment out existing lock-enabled locks in other databases (excluding distro, ibus, local.d)
mapfile -t LOCKFILES < <(grep -R "^/org/gnome/desktop/screensaver/lock-enabled$" "$DCONF_DB_DIR" 2>/dev/null \
    | grep -v 'distro\|ibus\|local.d' | cut -d':' -f1 | sort -u)

if [ "${#LOCKFILES[@]}" -ne 0 ]; then
    sed -i -E "s|^/org/gnome/desktop/screensaver/lock-enabled$|#&|" "${LOCKFILES[@]}" || true
fi

LOCKFILE="$LOCKS_DIR/00-security-settings-lock"
touch "$LOCKFILE"

if ! grep -q "^/org/gnome/desktop/screensaver/lock-enabled$" "$LOCKFILE"; then
    echo "/org/gnome/desktop/screensaver/lock-enabled" >> "$LOCKFILE"
fi

chmod -R u=rwX,go=rX "$DCONF_DB_DIR"
(umask 0022 && dconf update || true)

# -------------------------
# Handle lock-enabled value
# -------------------------

DCONFFILE="$LOCAL_DIR/00-security-settings"

# Comment out existing lock-enabled settings in other databases (excluding distro, ibus, local.d)
mapfile -t SETTINGSFILES < <(grep -R "\[org/gnome/desktop/screensaver\]" "$DCONF_DB_DIR" 2>/dev/null \
    | grep -v 'distro\|ibus\|local.d' | cut -d':' -f1 | sort -u)

if [ "${#SETTINGSFILES[@]}" -ne 0 ]; then
    if grep -q "^\s*lock-enabled\s*=" "${SETTINGSFILES[@]}" 2>/dev/null; then
        sed -Ei "s/(^\s*)lock-enabled(\s*=)/#\1lock-enabled\2/g" "${SETTINGSFILES[@]}" || true
    fi
fi

mkdir -p "$LOCAL_DIR"
touch "$DCONFFILE"

# Ensure [org/gnome/desktop/screensaver] section exists
if ! grep -q "^\s*\[org/gnome/desktop/screensaver\]\s*$" "$DCONFFILE"; then
    printf '\n[org/gnome/desktop/screensaver]\n' >> "$DCONFFILE"
fi

# Set lock-enabled=true
escaped_value="$(printf '%s' "true" | sed -e 's/\\/\\\\/g')"
if grep -q "^\s*lock-enabled\s*=" "$DCONFFILE"; then
    sed -i "s/^\s*lock-enabled\s*=.*/lock-enabled=${escaped_value}/" "$DCONFFILE"
else
    sed -i "\\|\[org/gnome/desktop/screensaver\]|a lock-enabled=${escaped_value}" "$DCONFFILE"
fi

chmod -R u=rwX,go=rX "$DCONF_DB_DIR"
(umask 0022 && dconf update || true)

echo "[+] Remediation complete: GNOME screensaver lock enabled (lock-enabled=true) and locked via dconf (local.d)."
