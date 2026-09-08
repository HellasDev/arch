#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 11-mkinitcpio.sh
# HOOKS (systemd + sd-encrypt), linux.preset για UKI,
# δημιουργία /efi/EFI/Linux, και mkinitcpio -P.
# ============================================================
. "$(dirname "$0")/_common.sh"

MKB="${MNT}/etc/mkinitcpio.conf"

title "mkinitcpio — HOOKS + UKI preset"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."

[ -f "$MKB" ] || fail "Δεν βρήκα $MKB. Τρέξε πρώτα το #3."

# --- 1. HOOKS -----------------------------------------------------
say "Αντικατάσταση HOOKS..."
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode kms modconf keyboard keymap sd-vconsole block sd-encrypt filesystems)/' "$MKB"

grep '^HOOKS=' "$MKB"

# --- 2. linux.preset ----------------------------------------------
say "Γράφω ${MNT}/etc/mkinitcpio.d/linux.preset..."
cat > ${MNT}/etc/mkinitcpio.d/linux.preset << 'EOF'
# mkinitcpio preset file for the 'linux' package
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default' 'fallback')

default_uki="/efi/EFI/Linux/arch-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
EOF

echo "--- ${MNT}/etc/mkinitcpio.d/linux.preset ---"
cat ${MNT}/etc/mkinitcpio.d/linux.preset

# --- 3. Δημιουργία φακέλου UKI + mkinitcpio ----------------------
say "Δημιουργία ${MNT}/efi/EFI/Linux..."
mkdir -p ${MNT}/efi/EFI/Linux

say "Τρέχω mkinitcpio -P (μέσα στο chroot)..."
run arch-chroot ${MNT} mkinitcpio -P

say "Αρχεία UKI:"
ls -lh ${MNT}/efi/EFI/Linux

say "ΤΕΛΟΣ #11 — mkinitcpio έτοιμο."