#!/usr/bin/env bash
# Symlink this repo's files into ~/.config so the repo stays the source of truth.
# Existing regular files are backed up to <name>.bak first.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config
for f in starship_colors.sh starship.toml.tmpl; do
    target=~/.config/$f
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$target.bak"
        echo "backed up $target -> $target.bak"
    fi
    ln -sfn "$repo/$f" "$target"
    echo "linked $target -> $repo/$f"
done
grep -q 'starship_colors.sh' ~/.bashrc 2>/dev/null || echo "Add the lines in bashrc.snippet to ~/.bashrc"
