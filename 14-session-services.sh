#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 14-session-services.sh
# Τρέχει ΜΕΤΑ το reboot, μέσα στο νέο σύστημα,
# ως ο κανονικός χρήστης (hellasdev).
#
# Ενεργοποιεί τα session services για να δουλεύει σωστά ο niri:
#   - pipewire (+ pulse) & wireplumber : ήχος
#   - gnome-keyring                     : keyring / ssh
#   - xdg-user-dirs                     : φάκελοι χρήστη
#   - polkit / xdg-desktop-portals      : έλεγχος ότι είναι ενεργά
# ============================================================

say()   { printf '\033[1;34m[+] %s\033[0m\n' "$1"; }
warn()  { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }
fail()  { printf '\033[1;31m[!!] %s\033[0m\n' "$1"; exit 1; }

[ "$(id -u)" -eq 0 ] && fail "Τρέξε το ΩΣ ΚΑΝΟΝΙΚΟΣ ΧΡΗΣΤΗΣ (hellasdev), όχι ως root."

title "Session services (niri)"

# --- 1. Ήχος: pipewire + wireplumber ---------------------------
say "Ενεργοποίηση pipewire & wireplumber..."
systemctl --user enable \
    pipewire.socket \
    pipewire-pulse.socket \
    wireplumber.service

# --- 2. GNOME keyring --------------------------------------------
say "Ενεργοποίηση gnome-keyring..."
systemctl --user enable gnome-keyring-daemon.socket

# --- 3. Φάκελοι χρήστη -------------------------------------------
say "Ενεργοποίηση xdg-user-dirs..."
systemctl --user enable xdg-user-dirs.service

# --- 4. Έλεγχοι ------------------------------------------------
say "Έλεγχος polkit (system):"
systemctl is-active polkit.service >/dev/null 2>&1 && \
    say "  polkit ενεργό" || \
    warn "  polkit δεν φαίνεται ενεργό (ξεκινά αυτόματα όταν χρειαστεί)"

say "Έλεγχος xdg-desktop-portal (DBus στατικό):"
systemctl --user status xdg-desktop-portal.service --no-pager | head -3

say "ΤΕΛΟΣ #14 — Επανεκκίνηση session ή login/logout για εφαρμογή."