#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 5-pacstrap-gui.sh
# GUI / συνεδρία: niri, terminal, wayland, ήχος (pipewire),
# bluetooth, portals, γραμματοσειρές.
# ΕΚΤΕΛΕΙΤΑΙ μετά το #3 (προαιρετικά μετά το #4).
# ============================================================
. "$(dirname "$0")/_common.sh"

title "Pacstrap GUI πακέτα"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno. Τρέξε πρώτα το #3."

run pacstrap -K ${MNT} \
    niri quickshell ghostty xwayland-satellite xorg-xwayland systemsettings \
    gnome-keyring upower power-profiles-daemon brightnessctl \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack pavucontrol wireplumber \
    bluez bluez-utils blueman \
    noto-fonts noto-fonts-emoji

say "ΤΕΛΟΣ #5 — GUI πακέτα εγκαταστάθηκαν."