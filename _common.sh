#!/usr/bin/env bash

# ============================================================
# _common.sh - Κοινός βοηθητικός κώδικας για ΟΛΑ τα scripts
# Εκτελείται με source ( . ./_common.sh ) στην αρχή κάθε script.
# ============================================================

# --- Χρώματα / μηνύματα -------------------------------------
say()   { printf '\033[1;34m[+] %s\033[0m\n' "$1"; }
warn()  { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }
fail()  { printf '\033[1;31m[!!] %s\033[0m\n' "$1"; exit 1; }
title() { printf '\033[1;37m=== %s ===\033[0m\n' "$1"; }

# --- Ρίζα του νέου συστήματος -------------------------------
MNT="${MNT:-/mnt}"

# --- Εκτέλεση εντολής ----------------------------------------
run() { "$@"; }

# --- Έλεγχοι mount / συσκευών -------------------------------
mount_ok() { mountpoint -q "$MNT"; }
dev_ok()   { [ -e "$1" ]; }
crypt_ok() { [ -L "$1" ]; }

# --- Έλεγχος αν βρισκόμαστε σε chroot -----------------------
# is_chroot: 0=ΝΑΙ μέσα σε chroot, 1=ΟΧΙ (βρισκόμαστε στο live/host)
is_chroot() {
    local root_inode host_inode
    root_inode=$(ls -id /             | awk '{print $1}')
    host_inode=$(ls -id /proc/1/root/ | awk '{print $1}')
    [ "$root_inode" != "$host_inode" ]
}

# --- Sudoers: wheel χωρίς κωδικό ----------------------------
enable_wheel_nopasswd() {
    local sd="$MNT/etc/sudoers.d"
    mkdir -p "$sd"
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > "$sd/wheel-nopasswd"
    chmod 440 "$sd/wheel-nopasswd"
    say "Wheel group: sudo ΧΩΡΙΣ κωδικό ($sd/wheel-nopasswd)."
}

# --- Αυτόματη εκκίνηση μέσα σε arch-chroot ------------------
# rinchroot <path-to-script>
# Αν δεν είμαστε σε chroot, αντιγράφει το script στο $MNT,
# το τρέχει μέσα σε arch-chroot και επιστρέφει στο host.
rinchroot() {
    local script="$1"
    local name="$(basename "$script")"
    local src_dir="$(dirname "$script")"
    local dst="$MNT/root/.arch-install-scripts"

    if ! is_chroot; then
        mount_ok || fail "Το $MNT δεν είναι montarismeno."

        say "Χρειάζεται arch-chroot. Μπαίνω μόνος μου στο $MNT..."

        mkdir -p "$dst"

        cp "$script" "$dst/$name"
        cp "$src_dir/_common.sh" "$dst/_common.sh"

        chmod +x "$dst/$name"

        run arch-chroot "$MNT" "/root/.arch-install-scripts/$name"

        rm -rf "$dst"

        say "Επέστρεψα στο host."
        exit 0
    fi
}
