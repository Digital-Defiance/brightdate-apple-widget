#!/usr/bin/env bash
#
# register-widget.sh
#
# Re-registers the BrightDate macOS widget with Launch Services and the
# WidgetKit daemon (chronod) so it reappears in the widget gallery.
#
# Why this is needed:
#   On macOS, the WidgetKit extension can silently get "stuck" pointing at a
#   stale path (e.g. an old Xcode Archive or a DerivedData build that was
#   cleaned). When that happens the widget disappears from the gallery and
#   simply rebuilding in Xcode does not restore it because Launch Services
#   still has the bad binding cached.
#
# What this script does:
#   1. Stops any running BrightDate processes.
#   2. Unregisters every Launch Services entry whose path contains
#      "brightdate.widget" (host app + extension, any location).
#   3. Finds the most recent built "BrightDate Widget.app" (or uses the path
#      you pass as the first argument).
#   4. Registers that app with lsregister.
#   5. Enables the extension with pluginkit.
#   6. Restarts chronod so it picks up the new binding.
#   7. Launches the host app and prints the current pluginkit status.
#
# Usage:
#   scripts/register-widget.sh                    # auto-detect newest build
#   scripts/register-widget.sh /path/to/App.app   # use a specific .app
#
# Tip: After running this once successfully, the next plain Build & Run in
#      Xcode should keep the widget visible.

set -euo pipefail

EXT_BUNDLE_ID="org.digitaldefiance.brightdate.widget.extension"
HOST_BUNDLE_ID="org.digitaldefiance.brightdate.widget"
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
info() { printf "  %s\n" "$*"; }
warn() { printf "\033[33m  %s\033[0m\n" "$*"; }
ok()   { printf "\033[32m  %s\033[0m\n" "$*"; }
err()  { printf "\033[31m  %s\033[0m\n" "$*" >&2; }

# ---------------------------------------------------------------------------
# 1. Locate the app to register
# ---------------------------------------------------------------------------
APP="${1:-}"

if [[ -z "$APP" ]]; then
  bold "[1/7] Locating most recent BrightDate Widget.app..."

  CANDIDATES=()

  # Custom temp build location used during development
  while IFS= read -r p; do CANDIDATES+=("$p"); done < <(
    find /tmp/bdw-build -maxdepth 6 -name "BrightDate Widget.app" 2>/dev/null || true
  )

  # Standard DerivedData builds
  while IFS= read -r p; do CANDIDATES+=("$p"); done < <(
    find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 \
      -path "*/Build/Products/*/BrightDate Widget.app" 2>/dev/null || true
  )

  # Archives (last resort — useful right after archiving)
  while IFS= read -r p; do CANDIDATES+=("$p"); done < <(
    find "$HOME/Library/Developer/Xcode/Archives" -maxdepth 6 \
      -path "*/Products/Applications/BrightDate Widget.app" 2>/dev/null || true
  )

  if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    err "No BrightDate Widget.app found."
    err "Build the app in Xcode first, or pass a path:"
    err "    $0 /path/to/BrightDate\\ Widget.app"
    exit 1
  fi

  # Pick the most recently modified one
  APP=$(printf '%s\n' "${CANDIDATES[@]}" \
    | while IFS= read -r p; do
        printf '%s\t%s\n' "$(stat -f %m "$p")" "$p"
      done \
    | sort -rn | head -1 | cut -f2-)

  ok "Found: $APP"
else
  bold "[1/7] Using app path from argument..."
  if [[ ! -d "$APP" ]]; then
    err "Path does not exist: $APP"
    exit 1
  fi
  ok "Using: $APP"
fi

EXT="$APP/Contents/PlugIns/BrightDateExtension.appex"
if [[ ! -d "$EXT" ]]; then
  err "Extension not found inside app:"
  err "    $EXT"
  err "Make sure the host target embeds the widget extension."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Stop any running BrightDate processes
# ---------------------------------------------------------------------------
bold "[2/7] Stopping any running BrightDate processes..."
pkill -9 -f "BrightDate Widget"  2>/dev/null && info "killed host"      || info "host not running"
pkill -9 -f "BrightDateExtension" 2>/dev/null && info "killed extension" || info "extension not running"
sleep 1

# ---------------------------------------------------------------------------
# 3. Unregister stale Launch Services entries for our bundle IDs
# ---------------------------------------------------------------------------
bold "[3/7] Unregistering stale Launch Services entries..."

# Dump LS and extract every Path = "..." line that belongs to a record whose
# identifier contains "brightdate.widget". The awk state machine tracks the
# current record's identifier so we only unregister our own paths (never
# unrelated system extensions).
"$LSREG" -dump 2>/dev/null | awk '
  /^-+$/                                              { id="" }
  /^[[:space:]]*bundle id:/                           { next }
  /^[[:space:]]*identifier:.*brightdate\.widget/      { id="ours" }
  /^[[:space:]]*identifier:/ && $0 !~ /brightdate/    { id="" }
  /^[[:space:]]*path:/ && id=="ours" {
    sub(/^[[:space:]]*path:[[:space:]]*/, "")
    print
  }
' | sort -u | while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  info "unreg: $p"
  "$LSREG" -u "$p" >/dev/null 2>&1 || true
done

# ---------------------------------------------------------------------------
# 4. Register the fresh build
# ---------------------------------------------------------------------------
bold "[4/7] Registering fresh build..."
"$LSREG" -f -R -trusted "$APP"
ok "registered host + embedded extension"

# ---------------------------------------------------------------------------
# 5. Enable the widget extension
# ---------------------------------------------------------------------------
bold "[5/7] Enabling widget extension..."
pluginkit -e use -i "$EXT_BUNDLE_ID"
ok "pluginkit: extension enabled"

# ---------------------------------------------------------------------------
# 6. Restart the WidgetKit daemon so it re-reads the binding
# ---------------------------------------------------------------------------
bold "[6/7] Restarting WidgetKit daemon (chronod)..."
killall chronod 2>/dev/null && ok "chronod killed (launchd will respawn it)" \
                            || info "chronod was not running"
sleep 2

# ---------------------------------------------------------------------------
# 7. Launch the host app and verify
# ---------------------------------------------------------------------------
bold "[7/7] Launching host app and verifying..."
open "$APP"
sleep 4

echo
bold "pluginkit status for BrightDate:"
STATUS=$(pluginkit -m -v 2>&1 | grep -i brightdate || true)
if [[ -z "$STATUS" ]]; then
  warn "Extension not visible to pluginkit yet."
  warn "Open the widget gallery — if it still doesn't show, log out and back in."
else
  echo "$STATUS"
  if echo "$STATUS" | grep -q '^+'; then
    echo
    ok "Done. Open the widget gallery — BrightDate should be available."
  else
    echo
    warn "Extension is registered but disabled. Try:"
    warn "    pluginkit -e use -i $EXT_BUNDLE_ID"
  fi
fi
