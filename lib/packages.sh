apt_update() {
  apt-get update
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

install_packages() {
  apt_update
  apt_install debconf-utils unattended-upgrades
  echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
  dpkg-reconfigure -f noninteractive unattended-upgrades
}

test_run() {
  apt_install locales powermgmt-base
  echo
  echo "---- unattended-upgrade Dry-Run (Debug) ----"
  unattended-upgrade --dry-run --debug || true
}
