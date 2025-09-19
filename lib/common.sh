need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Bitte als root ausfuehren." >&2
    exit 1
  fi
}

ts() {
  date +%Y%m%d-%H%M%S
}

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp -a "$file" "${file}.bak.$(ts)"
  fi
}
