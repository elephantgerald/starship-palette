#!/usr/bin/env bash
# One-line installer for starship-palette (Ubuntu/Debian and Fedora/RHEL):
#   curl -fsSL https://raw.githubusercontent.com/elephantgerald/starship-palette/main/bootstrap.sh | bash
#
# Installs git, envsubst and curl, installs starship if it is missing, clones
# (or updates) the repo, then runs install.sh to link the config and wire ~/.bashrc.
#
# Override before running:
#   STARSHIP_PALETTE_DIR=~/starship-palette   # where the repo is cloned
#   STARSHIP_PALETTE_REPO=<git url>           # clone from a fork
#
# Everything lives inside main() so a partially downloaded script does nothing.

set -euo pipefail

main() {
    local dir="${STARSHIP_PALETTE_DIR:-$HOME/starship-palette}"
    local repo="${STARSHIP_PALETTE_REPO:-https://github.com/elephantgerald/starship-palette.git}"
    local sudo=""

    if [ "$(id -u)" -ne 0 ]; then
        command -v sudo >/dev/null || die "sudo is required to install packages"
        sudo="sudo"
    fi

    [ -r /etc/os-release ] || die "cannot detect distro (/etc/os-release missing)"
    # shellcheck disable=SC1091
    . /etc/os-release

    case " ${ID:-} ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*)
            say "Installing packages with apt (git, gettext-base, curl)"
            $sudo apt-get update -qq
            $sudo apt-get install -y -qq git gettext-base curl
            ;;
        *" fedora "*|*" rhel "*|*" centos "*)
            say "Installing packages with dnf (git, gettext, curl)"
            $sudo dnf install -y -q git gettext curl
            ;;
        *)
            die "unsupported distro '${ID:-unknown}'; install git, envsubst and starship by hand, then run install.sh"
            ;;
    esac

    if command -v starship >/dev/null; then
        say "starship already installed ($(starship --version | head -1))"
    else
        say "Installing starship with the official installer"
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y
    fi

    if [ -d "$dir/.git" ]; then
        say "Updating $dir"
        git -C "$dir" pull --ff-only -q
    elif [ -e "$dir" ]; then
        die "$dir exists and is not a git checkout; move it or set STARSHIP_PALETTE_DIR"
    else
        say "Cloning into $dir"
        git clone -q "$repo" "$dir"
    fi

    "$dir/install.sh"

    cat <<'EOF'

Done. Open a new terminal to see the prompt.

The powerline arrows and icons need a Nerd Font (https://www.nerdfonts.com).
On WSL, install the font in Windows and select it in your Windows Terminal profile.
EOF
}

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

main "$@"
