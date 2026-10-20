#!/usr/bin/env bash
# Symlink this repo's files into ~/.config so the repo stays the source of truth,
# then wire ~/.bashrc. Existing regular files are backed up to <name>.bak first.
# Safe to re-run.
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

touch ~/.bashrc
if grep -q 'starship_colors.sh' ~/.bashrc; then
    echo "~/.bashrc already sources starship_colors.sh"
elif grep -q 'starship init bash' ~/.bashrc; then
    # Don't add a second starship init; the palette must be sourced before the existing one
    echo "~/.bashrc already runs 'starship init bash'. Add this line just before it:"
    echo "    source ~/.config/starship_colors.sh"
else
    printf '\n' >> ~/.bashrc
    cat "$repo/bashrc.snippet" >> ~/.bashrc
    echo "added starship-palette block to ~/.bashrc"
fi
