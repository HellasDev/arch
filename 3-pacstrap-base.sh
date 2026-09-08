#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 3-pacstrap-βασικά.sh
# Βασικό σύστημα: kernel, systemd, btrfs, cryptsetup, network,
# LUKS tools, snapper, zram, editor κλπ.
# ΕΚΤΕΛΕΙΤΑΙ με το ${MNT} έτοιμο από το #2.
# ============================================================
. "$(dirname "$0")/_common.sh"

title "Pacstrap ΒΑΣΙΚΆ πακέτα"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno. Τρέξε πρώτα το #2."

run pacstrap -K ${MNT} \
    base base-devel linux linux-firmware amd-ucode \
    btrfs-progs btrfs-assistant dosfstools util-linux cryptsetup \
    tpm2-tss tpm2-tools dosfstools sbctl snapper snap-pac \
    zram-generator dbus-broker systemd-ukify \
    networkmanager openssh sudo nvim \
    ufw \
    sof-firmware reflector libva-utils udisks2-btrfs

say "ΤΕΛΟΣ #3 — Βάση εγκαταστάθηκε."