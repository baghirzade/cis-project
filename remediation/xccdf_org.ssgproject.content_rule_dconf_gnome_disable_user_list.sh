#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_disable_user_list"

echo "[*] Applying remediation for: $RULE_ID (disable GNOME user list via dconf)"

# Applicable only if gdm3 is installed
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] gdm3 is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Ensure dconf directory structure for user and gdm
mkdir -p /etc/dconf/profile
USER_PROFILE="/etc/dconf/profile/user"
GDM_PROFILE="/etc/dconf/profile/gdm"

# Ensure user profile has user-db:user and system-db:local
: > "${USER_PROFILE}"
if ! grep -Pzq "(?s)^\s*user-db:user.*\n\s*system-db:local" "${USER_PROFILE}"; then
    sed -i --follow-symlinks "1s/^/user-db:user\nsystem-db:local\n/" "${USER_PROFILE}"
fi

mkdir -p /etc/dconf/db/local.d

# Ensure gdm profile has user-db:user and system-db:gdm
: > "${GDM_PROFILE}"
if ! grep -Pzq "(?s)^\s*user-db:user.*\n\s*system-db:gdm" "${GDM_PROFILE}"; then
    sed -i --follow-symlinks "1s/^/user-db:user\nsystem-db:gdm\n/" "${GDM_PROFILE}"
fi

mkdir -p /etc/dconf/db/gdm.d

# Set permissions and update dconf
chmod -R u=rwX,go=rX /etc/dconf/profile
(umask 0022 && dconf update || true)

# Configure disable-user-list in gdm.d
DCONF_DB_DIR="/etc/dconf/db"
GDM_DIR="$DCONF_DB_DIR/gdm.d"
DCONFFILE="$GDM_DIR/00-security-settings"
LOCKS_DIR="$GDM_DIR/locks"

mkdir -p "$GDM_DIR"
mkdir -p "$LOCKS_DIR"

# Comment out disable-user-list settings in other dconf databases (excluding distro, ibus, gdm.d)
mapfile -t SETTINGSFILES < <(grep -R "\\[org/gnome/login-screen\\]" "$DCONF_DB_DIR" 2>/dev/null \
    | grep -v 'distro\|ibus\|gdm.d' | cut -d":" -f1 | sort -u)

if [ "${#SETTINGSFILES[@]}" -ne 0 ]; then
    if grep -q "^\s*disable-user-list\s*=" "${SETTINGSFILES[@]}" 2>/dev/null; then
        sed -Ei "s/(^\s*)disable-user-list(\s*=)/#\1disable-user-list\2/g" "${SETTINGSFILES[@]}" || true
    fi
fi

# Ensure [org/gnome/login-screen] section exists in target file
touch "$DCONFFILE"
if ! grep -q "^\s*\[org/gnome/login-screen\]\s*$" "$DCONFFILE"; then
    printf '\n[org/gnome/login-screen]\n' >> "$DCONFFILE"
fi

# Set disable-user-list=true in target file
escaped_value="$(printf '%s' "true" | sed -e 's/\\/\\\\/g')"
if grep -q "^\s*disable-user-list\s*=" "$DCONFFILE"; then
    sed -i "s/^\s*disable-user-list\s*=.*/disable-user-list=${escaped_value}/" "$DCONFFILE"
else
    sed -i "\\|\[org/gnome/login-screen\]|a disable-user-list=${escaped_value}" "$DCONFFILE"
fi

# Set permissions and update dconf databases
chmod -R u=rwX,go=rX "$DCONF_DB_DIR"
(umask 0022 && dconf update || true)

# Manage locks: ensure lock entry exists only in gdm.d/locks
mapfile -t LOCKFILES < <(grep -R "^/org/gnome/login-screen/disable-user-list$" "$DCONF_DB_DIR" 2>/dev/null \
    | grep -v 'distro\|ibus\|gdm.d' | cut -d":" -f1 | sort -u)

if [ "${#LOCKFILES[@]}" -ne 0 ]; then
    sed -i -E "s|^/org/gnome/login-screen/disable-user-list$|#&|" "${LOCKFILES[@]}" || true
fi

LOCKFILE="$LOCKS_DIR/00-security-settings-lock"
touch "$LOCKFILE"

if ! grep -q "^/org/gnome/login-screen/disable-user-list$" "$LOCKFILE"; then
    echo "/org/gnome/login-screen/disable-user-list" >> "$LOCKFILE"
fi

chmod -R u=rwX,go=rX "$DCONF_DB_DIR"
(umask 0022 && dconf update || true)

echo "[+] Remediation complete: GNOME login screen user list disabled and locked via dconf."
