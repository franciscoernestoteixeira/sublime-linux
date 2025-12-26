#!/usr/bin/env bash
set -euo pipefail

CLEAN_OLD=false

for arg in "$@"; do
  case "$arg" in
    --clean-old)
      CLEAN_OLD=true
      ;;
    *)
      die "Unknown option: $arg"
      ;;
  esac
done

APPDIR="$HOME/Applications"
BINDIR="$HOME/.local/bin"
DESKTOPDIR="$HOME/.local/share/applications"
CACHEDIR="$APPDIR/.cache/sublime"

ST_PAGE="https://www.sublimetext.com/download_thanks?target=x64-tar#direct-downloads"
SM_PAGE="https://www.sublimemerge.com/download_thanks?target=x64-tar#direct-downloads"

UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari"

mkdir -p "$APPDIR" "$BINDIR" "$DESKTOPDIR" "$CACHEDIR"

log(){ printf '%s\n' "$*" >&2; }
die(){ log "ERROR: $*"; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

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

resolve_tar_url() {
  local page_url="$1"
  curl -fsSL -H "User-Agent: $UA" "$page_url" \
    | grep -oE 'https://download\.sublimetext\.com/sublime_(text|merge)_build_[0-9]+_x64\.tar\.xz' \
    | head -n 1
}

# Build a versioned folder name based on the tarball URL, for example:
# https://download.sublimetext.com/sublime_text_build_4200_x64.tar.xz
# -> sublime_text_build_4200_x64
versioned_dir_from_url() {
  local url="$1"
  # Strip everything up to last "/" and remove ".tar.xz"
  echo "$url" | sed -E 's|.*/||; s|\.tar\.xz$||'
}

download_tarball() {
  local url="$1" out="$2"
  rm -f "$out"
  curl -fL --retry 3 --retry-delay 1 -H "User-Agent: $UA" -o "$out" "$url"
  # Validate archive by listing (more reliable than xz -t for our use)
  tar -tf "$out" >/dev/null 2>&1 || die "Downloaded file is not a readable tar archive (likely HTML): $out"
}

install_one() {
  local key="$1"          # sublime_text | sublime_merge
  local page="$2"
  local extracted_root="$3"  # sublime_text | sublime_merge (folder inside tar)
  local bin="$4"          # sublime_text | sublime_merge (binary path inside extracted folder)
  local icon_rel="$5"     # Icon/128x128/...
  local desktop_cmd="$6"  # subl | smerge
  local categories="$7"

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

  local tmp
  tmp="$(mktemp -d)"

  log "==> Extracting ${key} to temp..."
  tar -xf "$cache_file" -C "$tmp"

  # The tar extracts to a stable folder name (e.g., sublime_text/). Move it into a versioned folder.
  local src="$tmp/$extracted_root"
  [[ -d "$src" ]] || die "Expected extracted folder not found: $src"

  local target="$APPDIR/$versioned_dir"
  log "==> Installing to: $target"
  rm -rf "$target"
  mv "$src" "$target"
  rm -rf "$tmp"

  # Stable current symlink (for desktop shortcuts and CLI)
  ln -sfn "$target" "$APPDIR/${key}-current"

  # CLI launcher
  ln -sfn "$APPDIR/${key}-current/$bin" "$BINDIR/$desktop_cmd"

  # Desktop shortcut
  cat > "$DESKTOPDIR/${desktop_cmd}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$([ "$key" = "sublime_text" ] && echo "Sublime Text" || echo "Sublime Merge")
Exec=$APPDIR/${key}-current/$bin %F
Icon=$APPDIR/${key}-current/$icon_rel
Categories=$categories
Terminal=false
StartupNotify=true
EOF

  log "==> Installed: $target"

  clean_old_versions "$key" "$versioned_dir"
}

clean_old_versions() {
  local key="$1"          # sublime_text | sublime_merge
  local keep_dir="$2"     # versioned folder to keep

  $CLEAN_OLD || return 0

  log "==> Cleaning old versions for ${key}..."

  find "$APPDIR" -maxdepth 1 -type d \
    -name "${key}_build_*_x64" \
    ! -name "$keep_dir" \
    -exec rm -rf {} +

  log "==> Old versions removed for ${key}"
}

# NOTE: extracted_root is the folder inside the tarball (as you saw: "sublime_text/").
install_one "sublime_text"  "$ST_PAGE" "sublime_text"  "sublime_text"  "Icon/128x128/sublime-text.png"  "subl"   "Development;TextEditor;"
install_one "sublime_merge" "$SM_PAGE" "sublime_merge" "sublime_merge" "Icon/128x128/sublime-merge.png" "smerge" "Development;RevisionControl;"

# Optional refresh
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOPDIR" >/dev/null 2>&1 || true

# Updater command
cat > "$BINDIR/update-sublime" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/Applications/install-sublime.sh"
EOF
chmod +x "$BINDIR/update-sublime"

log ""
log "Done."
log "Installed under: $APPDIR"
log "Commands:        subl, smerge"
log "Updater:         update-sublime"

exit 0
