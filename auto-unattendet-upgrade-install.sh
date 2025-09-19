#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/lib/distro.sh"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/lib/packages.sh"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/lib/config.sh"

main() {
  need_root
  detect_distro
  install_packages
  write_50unattended_upgrades "$DISTRO_ID"
  write_10periodic
  test_run
  echo
  echo "Fertig. Config gesichert und gesetzt. Distro: ${DISTRO_ID}${DISTRO_CODENAME:+ (${DISTRO_CODENAME})}"
  echo "Backups liegen als *.bak.$(date +%Y%m%d)* in /etc/apt/apt.conf.d/"
}

main "$@"
