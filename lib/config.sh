render_debian_origins() {
  cat <<'EOF'
  // Debian release, updates, security
  "origin=Debian,codename=${distro_codename}";
  "origin=Debian,codename=${distro_codename}-updates";
  "origin=Debian,codename=${distro_codename}-security";
EOF
}

render_ubuntu_origins() {
  cat <<'EOF'
  // Ubuntu release, updates, security, backports
  "origin=Ubuntu,codename=${distro_codename}";
  "origin=Ubuntu,codename=${distro_codename}-updates";
  "origin=Ubuntu,codename=${distro_codename}-security";
  "origin=Ubuntu,codename=${distro_codename}-backports";
EOF
}

render_common_origins() {
  cat <<'EOF'
  // Proxmox Enterprise (kernel weiter handhaben)
  "o=Proxmox,l=Proxmox VE Enterprise Debian Repository";

  // CrowdSec
  "origin=packagecloud.io/crowdsec/crowdsec,codename=${distro_codename}";

  // Netbird (Artifactory, stabil bleibt fix)
  "origin=Artifactory,codename=stable";

  // PostgreSQL (PGDG)
  "origin=apt.postgresql.org,codename=${distro_codename}-pgdg";

  // MariaDB
  "origin=MariaDB,codename=${distro_codename}";

  // NodeSource (nodistro)
  "origin=. nodistro,label=. nodistro";

  // NGINX (nginx.org)
  "origin=nginx,codename=${distro_codename}";

  // Docker CE
  "origin=Docker,label=Docker CE";

  // Proxmox PBS (No-Subscription)
  "origin=Proxmox,codename=${distro_codename}";

  // Proxmox PBS (Enterprise) nur falls aktiv
  // "origin=Proxmox,codename=${distro_codename},pocket=pbs-enterprise";

  // Sury PHP nur falls aktiv
  // "origin=deb.sury.org,codename=${distro_codename},component=main";

  // ZeroTier ggf. nodistro, per apt-cache policy pruefen
  // "origin=ZeroTier,codename=${distro_codename}";

  // Jellyfin (Origin fix)
  "origin=Jellyfin";

  // Netdata (repoconfig & stable)
  "o=Netdata,l=Netdata,site=repository.netdata.cloud";
  // alternativ etwas breiter
  // "o=Netdata,l=Netdata";

  // bashclub
  "site=apt.bashclub.org,a=${distro_codename},c=main";
  // falls Origin/Label variieren
  // "site=apt.bashclub.org";
EOF
}

render_common_footer() {
  cat <<'EOF'
// Automatische Bereinigung verwaister Abhaengigkeiten
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatischer Reboot nur bei Bedarf
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
//Unattended-Upgrade::Automatic-Reboot-Time "04:00";

// E-Mail-Benachrichtigung (Adresse eintragen oder leer lassen)
Unattended-Upgrade::Mail "";
Unattended-Upgrade::MailOnlyOnError "true";

// Dpkg-Optionen fuer non-interaktive Updates
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};
EOF
}

write_50unattended_upgrades() {
  local distro="$1"
  local target="/etc/apt/apt.conf.d/50unattended-upgrades"
  backup_file "$target"

  {
    cat <<'EOF'
Unattended-Upgrade::Origins-Pattern {
EOF

    case "$distro" in
      debian)
        render_debian_origins
        ;;
      ubuntu)
        render_ubuntu_origins
        ;;
      *)
        echo "Nicht unterstuetzte Distro: $distro" >&2
        return 1
        ;;
    esac

    render_common_origins

    cat <<'EOF'
};
EOF

    render_common_footer
  } > "$target"
}

write_10periodic() {
  local target="/etc/apt/apt.conf.d/10periodic"
  backup_file "$target"
  cat > "$target" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";
APT::Periodic::Enable "1";
EOF
}
