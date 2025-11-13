#!/bin/bash

_installYay() {
    if [[ ! $(_isInstalled "base-devel") == 0 ]]; then
        sudo pacman --noconfirm -S "base-devel"
    fi
    if [[ ! $(_isInstalled "git") == 0 ]]; then
        sudo pacman --noconfirm -S "git"
    fi
    if [ -d $HOME/Downloads/yay-bin ]; then
        rm -rf $HOME/Downloads/yay-bin
    fi
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    git clone https://aur.archlinux.org/yay-bin.git $HOME/Downloads/yay-bin
    cd $HOME/Downloads/yay-bin
    makepkg -si
    cd $temp_path
    echo ":: yay has been installed successfully."
}

_installParu() {
    if [[ ! $(_isInstalled "base-devel") == 0 ]]; then
        sudo pacman --noconfirm -S "base-devel"
    fi
    if [[ ! $(_isInstalled "git") == 0 ]]; then
        sudo pacman --noconfirm -S "git"
    fi
    if [ -d $HOME/Downloads/paru-bin ]; then
        rm -rf $HOME/Downloads/paru-bin
    fi
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    git clone https://aur.archlinux.org/paru-bin.git $HOME/Downloads/paru-bin
    cd $HOME/Downloads/paru-bin
    makepkg -si
    cd $temp_path
    echo ":: paru has been installed successfully."
}

_checkAURHelper() {
    if [[ $(_checkCommandExists "yay") == 0 ]]; then
        echo ":: yay is installed"
        yay_installed="true"
    fi
    if [[ $(_checkCommandExists "paru") == 0 ]]; then
        echo ":: paru is installed"
        paru_installed="true"
    fi
    if [[ $yay_installed == "true" ]] && [[ $paru_installed == "false" ]]; then
        echo ":: Using AUR Helper yay"
        aur_helper="yay"
    elif [[ $yay_installed == "false" ]] && [[ $paru_installed == "true" ]]; then
        echo ":: Using AUR Helper paru"
        aur_helper="paru"
    elif [[ $yay_installed == "false" ]] && [[ $paru_installed == "false" ]]; then
        echo ":: No AUR Helper installed"
        _selectAURHelper
        if [[ $aur_helper == "yay" ]]; then
            _installYay
        else
            _installParu
        fi
    else
        _selectAURHelper
    fi
}

packages=(
    breeze nwg-look qt6ct papirus-icon-theme bibata-cursor-theme catppuccin-gtk-theme-mocha
    ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-fira-code ttf-firacode-nerd otf-fira-code-symbol ttf-material-design-iconic-font ttf-cascadia-mono-nerd noto-fonts-cjk
    mate-polkit wlogout jq
    yazi wiremix fzf hyprlock
    power-profiles-daemon udiskie network-manager-applet brightnessctl
    cliphist stow git fish unzip fastfetch pamixer mako foot awww-git
    mpv mpd mpdris2-rs rmpc gtk4-layer-shell
    base-devel xdg-desktop-portal-gtk xdg-desktop-portal-gnome gnome-keyring
    python-flask python-requests
    pcmanfm-qt waybar ewwii-bin
    rofi rofimoji btop starship
)
