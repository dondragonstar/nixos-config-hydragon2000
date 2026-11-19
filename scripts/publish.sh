#!/usr/bin/env bash
# Copy the live NixOS config (/etc/nixos) and selected dotfiles into this
# git repository, then stage everything for review.
#
# /etc/nixos is the working tree. This repo is a snapshot meant for
# versioning and for bootstrapping other machines.
#
# Called automatically by the `flakeswitch` shell function after a
# successful `nixos-rebuild switch`, or manually: nixos-publish
set -euo pipefail

REPO="${NIXOS_REPO:-$HOME/nixos-config}"
SRC="/etc/nixos"

if [[ ! -d "$REPO/.git" ]]; then
  echo "error: $REPO is not a git repository" >&2
  exit 1
fi
if [[ ! -d "$SRC" ]]; then
  echo "error: $SRC does not exist" >&2
  exit 1
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "error: rsync is not installed" >&2
  exit 1
fi

# ─── 1. Mirror /etc/nixos -> $REPO/nixos ─────────────────────────────────
mkdir -p "$REPO/nixos"
rsync -rlptD --delete --no-owner --no-group \
  --exclude '.git/' \
  --exclude 'result' \
  --exclude 'result-*' \
  --exclude '*.bak*' \
  --exclude '.direnv/' \
  "$SRC"/ "$REPO/nixos"/

# ─── 2. Copy dotfiles -> $REPO/dotfiles ──────────────────────────────────
# Paths are relative to $HOME. Add or remove entries as you like.
dotfiles=(
  .config/mango/config.conf
  .config/noctalia/config.toml
  .config/rio/config.toml
  .config/rio/themes
  .config/fuzzel/fuzzel.ini
  .config/ghostty/config
  .config/ghostty/ryoku-colors
  .config/helix/config.toml
  .config/tmux/ryoku-colors.conf
  .config/starship.toml
  .config/btop/btop.conf
  .local/bin/mango-bar-fullscreen
  .local/bin/mango-layout-osd
)

for rel in "${dotfiles[@]}"; do
  src="$HOME/$rel"
  dst="$REPO/dotfiles/$rel"

  if [[ ! -e "$src" ]]; then
    echo "skip (not present): $rel"
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -d "$src" ]]; then
    rsync -rlptD --delete --no-owner --no-group "$src"/ "$dst"/
  else
    # rsync overwrites read-only files (cp -a would fail on them).
    rsync -rlptD --no-owner --no-group "$src" "$dst"
  fi
done

# ─── 3. Stage and report ─────────────────────────────────────────────────
git -C "$REPO" add -A

echo
if git -C "$REPO" diff --cached --quiet; then
  echo "Nothing changed since the last snapshot."
else
  echo "Staged changes:"
  git -C "$REPO" diff --cached --stat | tail -n 20
  echo
  echo "Review:  git -C $REPO diff --cached"
  echo "Commit:  git -C $REPO commit -m 'Update config'"
  echo "Push:    git -C $REPO push"
fi
