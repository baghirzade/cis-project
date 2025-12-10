#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_prelink_removed"

echo "[*] Fix tətbiq olunur: $RULE_ID (prelink paketi silinir)"

if ! command -v dpkg >/dev/null 2>&1; then
  echo "[!] dpkg tapılmadı, yəqin Debian/Ubuntu deyil. Fix SKIPPED."
  exit 0
fi

if command -v prelink >/dev/null 2>&1 || [ -f /usr/sbin/prelink ]; then
  echo " - prelink -ua işlədilir (bütün prelink-ləri geri qaytarır)"
  if ! prelink -ua; then
    echo "   [!] prelink -ua xətayla qayıtdı, davam edirik"
  fi
fi

echo " - 'prelink' paketi silinir (apt-get remove -y prelink)"
DEBIAN_FRONTEND=noninteractive apt-get remove -y prelink || {
  echo "[!] apt-get remove prelink uğursuz oldu"
  exit 1
}

echo "[+] Fix tamamlandı: prelink paketi silinib (və ya artıq quraşdırılmamışdı)"