#!/usr/bin/env bash
set -euo pipefail

APPDIR="$HOME/Applications"
BINDIR="$HOME/.local/bin"
DESKTOPDIR="$HOME/.local/share/applications"
CACHEDIR="$APPDIR/.cache/sublime"

ST_PAGE="https://www.sublimetext.com/download_thanks?target=x64-tar#direct-downloads"
SM_PAGE="https://www.sublimemerge.com/download_thanks?target=x64-tar#direct-downloads"

UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari"

log(){ printf '%s\n' "$*" >&2; }
die(){ log "ERROR: $*"; exit 1; }

usage() {
  cat >&2 <<'EOF'
Usage:
  install-sublime.sh [--only text|merge|both] [--clean-old] [--dry-run]
  install-sublime.sh --uninstall [--only text|merge|both] [--dry-run]

Options:
  --only text|merge|both   What to install/uninstall (default: text)
  --clean-old              Remove older versioned folders after successful install
  --dry-run                Print actions without downloading or changing anything
  --uninstall              Remove installed files for the selected target(s)
EOF
}

need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

# -----------------------------------------------------------------------------
# Options

CLEAN_OLD=false
DRY_RUN=false
UNINSTALL=false
ONLY="text"   # default: Sublime Text only

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean-old)
      CLEAN_OLD=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --only)
      [[ $# -ge 2 ]] || { usage; die "--only requires a value: text|merge|both"; }
      ONLY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown option: $1"
      ;;
  esac
done

case "$ONLY" in
  text|merge|both) ;;
  *) usage; die "Invalid --only value: $ONLY (expected text|merge|both)";;
esac

# -----------------------------------------------------------------------------
# Helpers for dry-run safe execution

run() {
  if $DRY_RUN; then
    log "[dry-run] $*"
    return 0
  fi
  "$@"
}

write_file() {
  local path="$1"
  if $DRY_RUN; then
    log "[dry-run] write file: $path"
    return 0
  fi
  cat > "$path"
}

# -----------------------------------------------------------------------------
# Preconditions and dirs

need curl
need tar
need grep
need head
need mktemp
need rm
need mv
need ln
need mkdir
need sed
need find

run mkdir -p "$APPDIR" "$BINDIR" "$DESKTOPDIR" "$CACHEDIR"

# -----------------------------------------------------------------------------
# Uninstall helpers

rm_path() {
  local p="$1"
  if [[ ! -e "$p" && ! -L "$p" ]]; then
    log "==> Not found (skip): $p"
    return 0
  fi
  if $DRY_RUN; then
    log "[dry-run] remove: $p"
    return 0
  fi
  rm -rf "$p"
  log "==> Removed: $p"
}

uninstall_one() {
  local key="$1"          # sublime_text | sublime_merge
  local desktop_cmd="$2"  # subl | smerge

  log ""
  log "==> Uninstalling: $key"

  # Remove versioned installs
  local candidates
  candidates="$(find "$APPDIR" -maxdepth 1 -type d -name "${key}_build_*_x64" -print 2>/dev/null || true)"
  if [[ -n "$candidates" ]]; then
    if $DRY_RUN; then
      log "[dry-run] would remove folders:"
      printf '%s\n' "$candidates" | sed 's/^/  - /' >&2
    else
      while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        rm -rf "$p"
      done <<< "$candidates"
      log "==> Removed versioned folders for $key"
    fi
  else
    log "==> No versioned folders found for $key"
  fi

  # Remove symlink
  rm_path "$APPDIR/${key}-current"

  # Remove launcher
  rm_path "$BINDIR/$desktop_cmd"

  # Remove desktop file
  rm_path "$DESKTOPDIR/${desktop_cmd}.desktop"
}

rebuild_or_remove_updater() {
  # Recreate update-sublime based on what remains installed.
  # If nothing remains, remove it.
  local has_text=false
  local has_merge=false

  [[ -L "$APPDIR/sublime_text-current" ]] && has_text=true
  [[ -L "$APPDIR/sublime_merge-current" ]] && has_merge=true

  if $DRY_RUN; then
    log "[dry-run] updater check:"
    log "  sublime_text-current: $has_text"
    log "  sublime_merge-current: $has_merge"
  fi

  if ! $has_text && ! $has_merge; then
    rm_path "$BINDIR/update-sublime"
    return 0
  fi

  local upd_only="text"
  if $has_text && $has_merge; then
    upd_only="both"
  elif $has_merge && ! $has_text; then
    upd_only="merge"
  else
    upd_only="text"
  fi

  # Note: we intentionally do not preserve --clean-old here (cannot infer safely).
  write_file "$BINDIR/update-sublime" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/Applications/install-sublime.sh" $( [[ "$upd_only" != "text" ]] && echo "--only $upd_only" )
EOF
  run chmod +x "$BINDIR/update-sublime"
  log "==> Updated updater: update-sublime (--only $upd_only)"
}

# If uninstall mode, do it early and exit.
if $UNINSTALL; then
  log "==> Uninstall mode enabled"
  log "==> Selection: --only $ONLY"

  if [[ "$ONLY" == "text" || "$ONLY" == "both" ]]; then
    uninstall_one "sublime_text" "subl"
  fi

  if [[ "$ONLY" == "merge" || "$ONLY" == "both" ]]; then
    uninstall_one "sublime_merge" "smerge"
  fi

  # Optional refresh
  if command -v update-desktop-database >/dev/null 2>&1; then
    run update-desktop-database "$DESKTOPDIR" >/dev/null 2>&1 || true
  fi

  rebuild_or_remove_updater

  log ""
  log "Done (uninstall)."
  exit 0
fi

# -----------------------------------------------------------------------------
# Install flow (unchanged logic below)

resolve_tar_url() {
  local page_url="$1"
  curl -fsSL -H "User-Agent: $UA" "$page_url" \
    | grep -oE 'https://download\.sublimetext\.com/sublime_(text|merge)_build_[0-9]+_x64\.tar\.xz' \
    | head -n 1
}

versioned_dir_from_url() {
  local url="$1"
  echo "$url" | sed -E 's|.*/||; s|\.tar\.xz$||'
}

download_tarball() {
  local url="$1" out="$2"

  if $DRY_RUN; then
    log "[dry-run] download: $url -> $out"
    return 0
  fi

  rm -f "$out"
  curl -fL --retry 3 --retry-delay 1 -H "User-Agent: $UA" -o "$out" "$url"
  tar -tf "$out" >/dev/null 2>&1 || die "Downloaded file is not a readable tar archive (likely HTML): $out"
}

clean_old_versions() {
  local key="$1"
  local keep_dir="$2"

  $CLEAN_OLD || return 0

  log "==> Cleaning old versions for ${key}..."

  local candidates
  candidates="$(find "$APPDIR" -maxdepth 1 -type d -name "${key}_build_*_x64" ! -name "$keep_dir" -print 2>/dev/null || true)"

  if [[ -z "$candidates" ]]; then
    log "==> No old versions to remove for ${key}"
    return 0
  fi

  if $DRY_RUN; then
    log "[dry-run] would remove:"
    printf '%s\n' "$candidates" | sed 's/^/  - /' >&2
    return 0
  fi

  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    rm -rf "$p"
  done <<< "$candidates"

  log "==> Old versions removed for ${key}"
}

install_one() {
  local key="$1"
  local page="$2"
  local extracted_root="$3"
  local bin="$4"
  local icon_rel="$5"
  local desktop_cmd="$6"
  local categories="$7"
  local desktop_name="$8"

  log ""
  log "==> Resolving ${key} tarball URL from page..."
  local tar_url
  tar_url="$(resolve_tar_url "$page" || true)"
  [[ -n "${tar_url}" ]] || die "Could not resolve tarball URL from: $page"
  log "==> Tarball: $tar_url"

  local versioned_dir
  versioned_dir="$(versioned_dir_from_url "$tar_url")"
  [[ -n "${versioned_dir}" ]] || die "Could not compute versioned folder name from URL: $tar_url"

  local cache_file="$CACHEDIR/${key}.tar.xz"
  log "==> Downloading ${key}..."
  download_tarball "$tar_url" "$cache_file"

  local target="$APPDIR/$versioned_dir"

  if $DRY_RUN; then
    log "[dry-run] would extract $cache_file, move '$extracted_root/' into: $target"
    log "[dry-run] would set symlink: $APPDIR/${key}-current -> $target"
    log "[dry-run] would set launcher: $BINDIR/$desktop_cmd -> $APPDIR/${key}-current/$bin"
    log "[dry-run] would write desktop file: $DESKTOPDIR/${desktop_cmd}.desktop (Name=${desktop_name})"
    clean_old_versions "$key" "$versioned_dir"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"

  log "==> Extracting ${key} to temp..."
  tar -xf "$cache_file" -C "$tmp"

  local src="$tmp/$extracted_root"
  [[ -d "$src" ]] || die "Expected extracted folder not found: $src"

  log "==> Installing to: $target"
  rm -rf "$target"
  mv "$src" "$target"
  rm -rf "$tmp"

  ln -sfn "$target" "$APPDIR/${key}-current"
  ln -sfn "$APPDIR/${key}-current/$bin" "$BINDIR/$desktop_cmd"

  write_file "$DESKTOPDIR/${desktop_cmd}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${desktop_name}
Exec=$APPDIR/${key}-current/$bin %F
Icon=$APPDIR/${key}-current/$icon_rel
Categories=$categories
Terminal=false
StartupNotify=true
EOF

  log "==> Installed: $target"

  clean_old_versions "$key" "$versioned_dir"
}

# Execute selection (default: text only)
if [[ "$ONLY" == "text" || "$ONLY" == "both" ]]; then
  install_one \
    "sublime_text" \
    "$ST_PAGE" \
    "sublime_text" \
    "sublime_text" \
    "Icon/128x128/sublime-text.png" \
    "subl" \
    "Development;TextEditor;" \
    "Sublime Text"
fi

if [[ "$ONLY" == "merge" || "$ONLY" == "both" ]]; then
  install_one \
    "sublime_merge" \
    "$SM_PAGE" \
    "sublime_merge" \
    "sublime_merge" \
    "Icon/128x128/sublime-merge.png" \
    "smerge" \
    "Development;RevisionControl;" \
    "Sublime Merge"
fi

# Optional refresh
if command -v update-desktop-database >/dev/null 2>&1; then
  run update-desktop-database "$DESKTOPDIR" >/dev/null 2>&1 || true
fi

# Updater command should preserve chosen flags (except --dry-run)
UPD_ARGS=()
$CLEAN_OLD && UPD_ARGS+=("--clean-old")
[[ "$ONLY" != "text" ]] && UPD_ARGS+=("--only" "$ONLY")

write_file "$BINDIR/update-sublime" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/Applications/install-sublime.sh" ${UPD_ARGS[*]+"${UPD_ARGS[@]}"}
EOF
run chmod +x "$BINDIR/update-sublime"

log ""
log "Done."
log "Installed under: $APPDIR"
log "Selection:       --only $ONLY"
log "Commands:        subl, smerge (created only for what you installed)"
log "Updater:         update-sublime"

exit 0
