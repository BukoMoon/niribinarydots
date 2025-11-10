#!/bin/bash

set -euo pipefail

if [ ! -t 0 ]; then
    curl -fsSL -o /tmp/install.sh https://raw.githubusercontent.com/BukoMoon/niribinarydots/refs/heads/main/install.sh
    chmod +x /tmp/install.sh
    exec /tmp/install.sh "$@"
fi

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

echo "Enter your sudo password:"
sudo echo
echo -e "${GREEN} Success. ${RESET}"

check_dep() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}X'$1' is not installed.${RESET}"
        return 1
    fi
}

if ! check_dep gum; then
    echo -e "${BLUE}Installing gum...${RESET}"
    if ! sudo pacman -S --noconfirm gum; then
        echo -e "${RED}X Failed to install gum. Please install it manually. ${RESET}"
        exit 1
    fi
fi

confirmation() {
    local title="$1"
    shift

    if [ -t 1 ]; then
        gum confirm "$title"
    else
        gum confirm "$title" --selected.backgrounds="100" --prompt.foreground="1000"
    fi
}

confirmation_alt() {
    local title="$1"
    shift

    if [ -t 1 ]; then
        gum confirm "$title"
    else
        gum confirm "$title" --selected.background="75" --prompt.foreground="1000"
    fi
}


info() { gum style --foreground "#49A22C" -- <<< " $1"; }

process() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

error() { gum style --foreground "#FF5555" -- <<< "X $1"; }

echo -e "${BLUE} BINARYDOTS FOR NIRI\n${RESET}"

if [[ $EUID -eq 0 ]]; then
    error "Please do not run this script as root.\n"
    exit 1
fi

echo -e "   Edited by BukoMoon\n\n"
confirmation "Proceed with setup?" || exit 0

if ! check_dep paru; then

    if confirmation "Install Paru?"; then
        info "Installing dependencies..."
        sudo pacman -S --needed base-devel git rust
        if [ ! -d "paru" ]; then
            process "Cloning paru repo..." git clone https://aur.archlinux.org/paru.git || error "Failed to clone paru"
        fi
        info "Building package..."
        cd paru
        makepkg -si
        cd ..
        rm -rf paru
        info "Packaage {paru} installed."
    else
        error "Aborting setup."
        rm -rf paru
        exit 1
    fi
fi

if process "Updating system..." bash -c '
    if ! paru -Syu --repo --noconfirm >/dev/null 2>&1; then
        error "System update failed. Try to update manually."
        exit 1
    fi
';then
    info "System updated."
else
    error "System update failed. Try manually."
    exit 1
fi

PACKAGES=(
    breeze nwg-look qt6ct papirus-icon-theme bibata-cursor-theme catppuccin-gtk-theme-mocha
    ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-fira-code ttf-firacode-nerd otf-fira-code-symbol ttf-material-design-iconic-font ttf-cascadia-mono-nerd noto-fonts-cjk
    polkit-kde-agent
    yazi wiremix fzf swaylock
    power-profiles-daemon udiskie network-manager-applet brightnessctl
    cliphist stow git fish unzip fastfetch pamixer mako foot awww-git
    mpv mpd mpdris2-rs rmpc
    base-devel xdg-desktop-portal-gtk xdg-desktop-portal-gnome gnome-keyring
    python-flask python-requests
    pcmanfm-qt waybar ewwii-bin
    rofi rofimoji btop starship
)

PACKAGES_URL="https://raw.githubusercontent.com/BukoMoon/niribinarydots/refs/heads/main/PACKAGES"
PACKAGES=($(curl -s "$PACKAGES_URL")) || true


if ! paru -S --needed "${PACKAGES[@]}"; then
    error "Package installaation failed."
    exit 1
else
    info "Installed packages."
fi

NVIDIGPU="yes"
if lspci | grep -qi 'NVIDIA'; then
    info "NVIDIA GPU detected."
    #if ! pacman -Qi nvidia-dkms >/dev/null 2>&1; then
    #     process "Installing nvidia-dkms (required for NVIDIA GPUs)..." paru -S --noconfirm --needed nvidia-dkms || error "Failed to install 'nvidia-dkms'. Please install manually"
    #     info "nvidia-dkms installed successfully."
    #else
    #    info "nvidia-dkms already installed."
    #fi
else
NVIDIGPU="no"
fi

if [ ! -d "./config" ]; then
    [ -d "$HOME/Dotfiles.old" ] && rm -rf "$HOME/Dotfiles.old" || true
    [ -d "$HOME/Dotfiles" ] && mv ~/Dotfiles ~/Dotfiles.old || true

    REPO_URL="https://github.com/BukoMoon/niribinarydots.git"
    PROXY_URL="https://gh-proxy.com/$REPO_URL"

    process "Cloning niribinarydots repo..." git clone "$PROXY_URL" ~/Dotfiles
    if [ $? -ne 0 ]; then
        echo "Proxy failed, trying direct GitHub clone..."
        process "Cloning binarydots repo (direct)..." git clone "$REPO_URL" || {
            error "Failed to clone repo."
            exit 1
        }
    fi

    info "Cloned Repo."

    process "Moving scripts and configs..." bash -c '

    [ -d "$HOME/dots.old" ] && rm -rf "$HOME/dots.old"

    mkdir -p "$HOME/dots.old"

    folders=(
        "binarydots" "cava" "ewwii" "fastfetch" "foot" "gtk-3.0" "gtk-4.0"
        "mako" "mpd" "mpv" "niri" pcmanfm-qt" "nwg-look" "qt6ct"
        "rmpc" "rofi" "waybar" "wiremix" "yazi" "wlogout" "scripts" "swaylock"
    )

    for item in "${folders[@]}"; do
        src="$HOME/Dotfiles/config/$item"
        dest="$HOME/.config/$item"

        if [ -d "$dest" ] && [ ! -L "$dest" ]; then
           [ -e "$HOME/dots.old/$item" ] && rm -rf "$HOME/dots.old/$item"
           mv "$dest" "$HOME/dots.old/" 2>/dev/null || true
        elif [ -L "$dest" ]; then
             rm "$dest" 2>/dev/null || true
        fi

        if [ -e "$src" ]; then
             ln -s "$src" "$dest"
        fi
    done

    chmod +x \
        "$HOME/Dotfiles/config/scripts/"* \
        "$HOME/Dotfiles/config/niri/scripts/"* \
        "$HOME/Dotfiles/config/ewwii/scripts/"* \
        "$HOME/Dotfiles/config/mako/scripts/"* || true
    '

    info "Linked scripts and config files."

    if [ "$NVIDIGPU" = 'yes' ]; then
        process "Setting up Nvidia GPU" bash -c '
        sudo mkdir -p /etc/nvidia/nvidia-application-profiles-rc.d/

        sudo touch /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json
    sudo echo "{
       "rules": [
           {
               "pattern": {
                   "feature": "procname",
                   "matches": "niri"
               },
               "profile": "Limit Free Buffer Pool On Wayland Compositors"
           }
       ],
       "profiles": [
           {
               "name": "Limit Free Buffer Pool On Wayland Compositors"
               "settings": [
                   {
                       "key": "GLVidHeapReuseRatio",
                       "value": 0
                   }
               ]
           }
       ]
    }" > /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositor.json
    '
    fi


    dconf write "/org/gnome/desktop/interface/color-scheme" '"prefer-dark"'
    info "Set UI to dark mode..."

    process "Setting up polkit agent..." systemctl --user enable --now polkit-kde-agent.service

    if [ $? -eq 0 ]; then
        info "Polkit agent setup successfully."
    else
        error "Failed to enable polkit agent."
    fi

    if confirmation_alt "Set up MPD? (Not Recommended for new users - its worth)"; then
        process "Setting up MPD" bash -c '

        systemctl --user enable mpd

        systemctl --user start mpd
        '

        if [ $? -eq 0 ]; then
            info "MPD setup succeeded"
        else
            error "MPD setup failed"
        fi
    else
        rm -rf ~/.config/rmpc/
        rm -rf ~/.config/mpd
        if [ -d "$HOME/dots.old/rmpc" ]; then
            cp -r "$HOME/dots.old/rmpc" "$HOME/.config/" > /dev/null 2>&1
        fi
        if [ -d "$HOME/dots.old/mpd" ]; then
            cp -r "$HOME/dots.old/mpd" "$HOME/.config" > /dev/null 2>&1
        fi
    fi

    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [ "$current_shell" != "/usr/bin/fish" ] && [ "$current_shell" != "/bin/fish" ]; then
        if confirmation_alt "Change default shell to fish?"; then
            if chsh -s /bin/fish "$USER"; then
                info "Default shell changed to fish."

                if confirmation_alt "Install some utils? (Highly Recommended)"; then
                    if process "Installing utilities" paru -S --needed eza ripgrep ; then
                        info "Successfully install utilities."
                    else
                        error "Failed to install utilities."
                    fi
                fi
            else
                error "Failed to change shell."
            fi
        fi
    fi

    ln -sf "$HOME/.config/niri/wallpapers/lines.jpg" "$HOME/.config/niri/wallppr.png"

    python ~/.config/niri/scripts/wallpapers.py changeWallpaper Lines >/dev/null 2>&1 & disown

    if pgrep niri-session >/dev/null; then
        info "Detected Niri session."

        process "Reloading Components..." bash -c '

        pkill waybar >/dev/null 2>&1 & disown

        if pgrep awww-daemon >/dev/null; then
           pkill awww-daemon
           sleep 0.5
        fi

        if pgrep ewwii >/dev/null; then
           killall ewwii
           ewwii daemon >/dev/null 2>&1 & disown
           for widget in "status" "desktopmusic" ; do
               ewwii open "$widget" >/dev/null 2>&1 &
           done
        fi

        setsid awww-daemon >/dev/null 2>&1 &
        '

        info "Reloaded Components."
    fi

    cd ..
    process "Cleaning up..." rm -rf niribinarydots
    info "Cleaned."

    $HOME/Dotfiles/config/scripts/change-theme -c Binary >> /dev/null
    echo -e "${GREEN} Installation complete! Please restart your computer!"

else
    info "Files already installed."
fi
