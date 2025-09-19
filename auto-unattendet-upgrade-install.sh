#!/usr/bin/env bash
# setup-unattended-upgrades.sh
set -Eeuo pipefail

need_root() { [[ $EUID -eq 0 ]] || { echo "Bitte als root ausführen."; exit 1; }; }
ts() { date +%Y%m%d-%H%M%S; }

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.bak.$(ts)"
  fi
}

detect_distro() {
  . /etc/os-release
  DISTRO_ID="${ID,,}"
  DISTRO_CODENAME="${VERSION_CODENAME:-}"
  # Fallbacks:
  if [[ -z "${DISTRO_CODENAME}" ]] && command -v lsb_release >/dev/null 2>&1; then
    DISTRO_CODENAME="$(lsb_release -sc || true)"
  fi
  if [[ -z "${DISTRO_ID}" ]]; then
    echo "Konnte Distribution nicht bestimmen."; exit 2
  fi
  case "$DISTRO_ID" in
    debian|ubuntu) ;;
    *)
      # Prüfe ID_LIKE
      if [[ "${ID_LIKE:-}" == *debian* ]]; then
        DISTRO_ID="debian"
      else
        echo "Unbekannte Distribution: ${ID} (ID_LIKE=${ID_LIKE:-n/a})"; exit 2
      fi
      ;;
  esac
}

install_packages() {
  apt-get update
  apt-get install -y debconf-utils unattended-upgrades
  # Auto-Updates einschalten (non-interactive)
  echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections
  dpkg-reconfigure -f noninteractive unattended-upgrades
}

write_50uu_debian() {
  local f="/etc/apt/apt.conf.d/50unattended-upgrades"
  backup_file "$f"
  # Wichtig: <<'EOF' lässt ${distro_codename} LITERAL stehen (apt ersetzt das selbst).
  cat > "$f" <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  // Debian Basis (Release + Updates + Security)
  "origin=Debian,codename=${distro_codename}";
  "origin=Debian,codename=${distro_codename}-updates";
  "origin=Debian,codename=${distro_codename}-security";

  // Proxmox Enterprise (Achtung: Kernel i. d. R. weiterhin blocken!)
  "o=Proxmox,l=Proxmox VE Enterprise Debian Repository";

  // CrowdSec
  "origin=packagecloud.io/crowdsec/crowdsec,codename=${distro_codename}";
  // oder allgemeiner: "origin=packagecloud.io/crowdsec/crowdsec";

  // Netbird (Artifactory, codename meist stabil → bleibt fix)
  "origin=Artifactory,codename=stable";

  // PostgreSQL (PGDG)
  "origin=apt.postgresql.org,codename=${distro_codename}-pgdg";

  // MariaDB
  "origin=MariaDB,codename=${distro_codename}";

  // NodeSource (nodistro)
  "origin=. nodistro,label=. nodistro";

  // NGINX (offizielles nginx.org Repo)
  "origin=nginx,codename=${distro_codename}";

  // Docker CE
  "origin=Docker,label=Docker CE";

  // Proxmox PBS (No-Subscription)
  "origin=Proxmox,codename=${distro_codename}";

  // Proxmox PBS (Enterprise) – nur falls aktiv
  // "origin=Proxmox,codename=${distro_codename},pocket=pbs-enterprise";

  // Sury PHP – nur falls Repo aktiv
  // "origin=deb.sury.org,codename=${distro_codename},component=main";

  // ZeroTier – manche Repos geben „nodistro“ zurück, prüfen mit apt-cache policy
  // "origin=ZeroTier,codename=${distro_codename}";

  // Jellyfin (Origin bleibt fix, kein Codename nötig)
  "origin=Jellyfin";

  // Netdata (repoconfig & stable)
  "o=Netdata,l=Netdata,site=repository.netdata.cloud";
  // alternativ etwas breiter:
  // "o=Netdata,l=Netdata";

  // bashclub (bookworm, main)
  "site=apt.bashclub.org,a=${distro_codename},c=main";
  // falls deren Origin/Label variieren:
  // "site=apt.bashclub.org";

};

// Automatische Bereinigung verwaister Abhängigkeiten
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatischer Reboot nur wenn nötig
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
//Unattended-Upgrade::Automatic-Reboot-Time "04:00";

// E-Mail-Benachrichtigung (Adresse eintragen oder leer lassen)
Unattended-Upgrade::Mail "";
Unattended-Upgrade::MailOnlyOnError "true";

// Dpkg-Optionen, um interaktive Abfragen zu vermeiden
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};
EOF
}

write_50uu_ubuntu() {
  local f="/etc/apt/apt.conf.d/50unattended-upgrades"
  backup_file "$f"
  cat > "$f" <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  // Ubuntu Basis (Release + Updates + Security + Backports)
  "origin=Ubuntu,codename=${distro_codename}";
  "origin=Ubuntu,codename=${distro_codename}-updates";
  "origin=Ubuntu,codename=${distro_codename}-security";
  "origin=Ubuntu,codename=${distro_codename}-backports";

  // Proxmox Enterprise (Achtung: Kernel i. d. R. weiterhin blocken!)
  "o=Proxmox,l=Proxmox VE Enterprise Debian Repository";

  // CrowdSec
  "origin=packagecloud.io/crowdsec/crowdsec,codename=${distro_codename}";
  // oder allgemeiner: "origin=packagecloud.io/crowdsec/crowdsec";

  // Netbird (Artifactory, codename meist stabil → bleibt fix)
  "origin=Artifactory,codename=stable";

  // PostgreSQL (PGDG)
  "origin=apt.postgresql.org,codename=${distro_codename}-pgdg";

  // MariaDB
  "origin=MariaDB,codename=${distro_codename}";

  // NodeSource (nodistro)
  "origin=. nodistro,label=. nodistro";

  // NGINX (offizielles nginx.org Repo)
  "origin=nginx,codename=${distro_codename}";

  // Docker CE
  "origin=Docker,label=Docker CE";

  // Proxmox PBS (No-Subscription)
  "origin=Proxmox,codename=${distro_codename}";

  // Proxmox PBS (Enterprise) – nur falls aktiv
  // "origin=Proxmox,codename=${distro_codename},pocket=pbs-enterprise";

  // Sury PHP – nur falls Repo aktiv
  // "origin=deb.sury.org,codename=${distro_codename},component=main";

  // ZeroTier – manche Repos geben „nodistro“ zurück, prüfen mit apt-cache policy
  // "origin=ZeroTier,codename=${distro_codename}";

  // Jellyfin (Origin bleibt fix, kein Codename nötig)
  "origin=Jellyfin";

  // Netdata (repoconfig & stable)
  "o=Netdata,l=Netdata,site=repository.netdata.cloud";
  // alternativ etwas breiter:
  // "o=Netdata,l=Netdata";

  // bashclub (Ubuntu, main)
  "site=apt.bashclub.org,a=${distro_codename},c=main";
  // falls deren Origin/Label variieren:
  // "site=apt.bashclub.org";
};

// Automatische Bereinigung verwaister Abhängigkeiten
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatischer Reboot nur wenn nötig
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
//Unattended-Upgrade::Automatic-Reboot-Time "04:00";

// E-Mail-Benachrichtigung (Adresse eintragen oder leer lassen)
Unattended-Upgrade::Mail "";
Unattended-Upgrade::MailOnlyOnError "true";

// Dpkg-Optionen, um interaktive Abfragen zu vermeiden
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};
EOF
}

write_10periodic() {
  local f="/etc/apt/apt.conf.d/10periodic"
  backup_file "$f"
  cat > "$f" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";
APT::Periodic::Enable "1";
EOF
}

test_run() {
  # Vom Wunsch: Testpakete installieren und Dry-Run starten
  apt-get install -y locales powermgmt-base
  echo
  echo "---- unattended-upgrade Dry-Run (Debug) ----"
  unattended-upgrade --dry-run --debug || true
}

main() {
  need_root
  detect_distro
  install_packages
  case "$DISTRO_ID" in
    debian)  write_50uu_debian ;;
    ubuntu)  write_50uu_ubuntu ;;
    *) echo "Nicht unterstützte Distro: $DISTRO_ID"; exit 3 ;;
  esac
  write_10periodic
  test_run
  echo
  echo "Fertig. Config gesichert & gesetzt. Distro: ${DISTRO_ID}${DISTRO_CODENAME:+ (${DISTRO_CODENAME})}"
  echo "Backups befinden sich bei Bedarf als *.bak.$(date +%Y%m%d)* in /etc/apt/apt.conf.d/"
}

main "$@"
