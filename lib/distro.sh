detect_distro() {
  if [[ ! -r /etc/os-release ]]; then
    echo "Konnte /etc/os-release nicht lesen." >&2
    exit 2
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID,,}"
  DISTRO_CODENAME="${VERSION_CODENAME:-}"

  if [[ -z "$DISTRO_CODENAME" ]] && command -v lsb_release >/dev/null 2>&1; then
    DISTRO_CODENAME="$(lsb_release -sc || true)"
  fi

  if [[ -z "$DISTRO_ID" ]]; then
    echo "Konnte Distribution nicht bestimmen." >&2
    exit 2
  fi

  case "$DISTRO_ID" in
    debian|ubuntu)
      ;;
    *)
      if [[ "${ID_LIKE:-}" == *debian* ]]; then
        DISTRO_ID="debian"
      else
        echo "Unbekannte Distribution: ${ID:-?} (ID_LIKE=${ID_LIKE:-n/a})" >&2
        exit 2
      fi
      ;;
  esac
}
