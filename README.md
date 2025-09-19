# unattended-upgrade

Automates enabling unattended security and package updates on Debian- and Ubuntu-based systems with curated third-party repository support.

## Features
- Detects Debian or Ubuntu derivatives via `/etc/os-release` (falls back to `lsb_release`).
- Installs and configures `unattended-upgrades`, `debconf-utils`, and periodic APT maintenance tasks.
- Writes hardened `/etc/apt/apt.conf.d/50unattended-upgrades` and `10periodic` templates with automatic backups of existing files.
- Includes origins for common vendors (Proxmox, CrowdSec, Docker, Netdata, etc.) while leaving optional entries commented.
- Performs a dry-run of `unattended-upgrade` to verify the configuration.

## Repository Layout
- `auto-unattendet-upgrade-install.sh` ? entrypoint script orchestrating the setup.
- `lib/common.sh` ? shared helpers (root check, timestamped backups).
- `lib/distro.sh` ? distro detection and environment variables.
- `lib/packages.sh` ? apt wrapper functions and optional dry-run test.
- `lib/config.sh` ? renders distro-specific and shared unattended-upgrades templates.

## Requirements
- Debian or Ubuntu host with `apt-get`, `dpkg`, and `debconf-set-selections` available.
- Root privileges (`sudo`) to modify `/etc/apt/apt.conf.d/` and install packages.

## Usage
1. Copy or clone this repository onto the target machine.
2. Run the installer as root:
   ```bash
   sudo ./auto-unattendet-upgrade-install.sh
   ```
3. Review the console output for backup locations and the `unattended-upgrade --dry-run` summary.
4. Adjust optional origins inside `lib/config.sh` if you need additional repositories before rerunning.

## Maintenance Notes
- Existing APT config files are backed up as `*.bak.<timestamp>` in `/etc/apt/apt.conf.d/`.
- Update the templates in `lib/config.sh` to add or remove third-party repositories.
- Re-run the installer after repository changes or major distro upgrades to refresh settings.
