#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 13-verify-unmount-reboot.sh
# Τελικός έλεγχος (fstab/crypttab/cmdline/swap/UKI/subvolumes),
# αποσύνδεση, κλείσιμο crypt, και restart στο firmware setup.
# ΠΡΟΣΟΧΗ: το restart γίνεται ΜΟΝΟ αν πεις YES.
# ============================================================
. "$(dirname "$0")/_common.sh"

title "ΤΕΛΙΚΟΣ ΕΛΕΓΧΟΣ"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."

echo "===== FSTAB ====="
cat ${MNT}/etc/fstab

echo "===== CRYPTTAB ====="
cat ${MNT}/etc/crypttab.initramfs

echo "===== CMDLINE ====="
cat ${MNT}/etc/kernel/cmdline

echo "===== SWAP ====="
run swapon --show

echo "===== UKI ====="
ls -lh ${MNT}/efi/EFI/Linux

echo "===== SUBVOLUMES ====="
run btrfs subvolume list ${MNT}

say "Έλεγχοι: θέλουμε να βλέπουμε @swap, /swap/swapfile,"
say "και στο cmdline: resume=UUID=... και resume_offset=..."

# --- Έλεγχος μήπως κάτι δεν χάθηκε -------------------------------
echo
say "Έλεγχο κρίσιμα στοιχεία..."
grep -q 'subvol=/@swap' ${MNT}/etc/fstab && say "  OK fstab: @swap"   || warn "  ΔΕΝ βρήκα @swap στο fstab"
ls ${MNT}/swap/swapfile >/dev/null 2>&1 && say "  OK: swapfile υπάρχει" || warn "  ΔΕΝ βρήκα swapfile"
grep -q 'resume=' ${MNT}/etc/kernel/cmdline && say "  OK cmdline: resume=" || warn "  ΔΕΝ βρήκα resume= στο cmdline"
grep -q 'resume_offset=' ${MNT}/etc/kernel/cmdline && say "  OK cmdline: resume_offset=" || warn "  ΔΕΝ βρήκα resume_offset="

# --- Αποσύνδεση + κλείσιμο ------------------------------------------
echo
say "Απενεργοποίηση swap..."
run swapoff "${MNT}/swap/swapfile"

say "Αποσύνδεση ${MNT} (umount)..."
run umount -R ${MNT}

say "Κλείσιμο crypt 'root'..."
run cryptsetup close root

say "Ο δίσκος είναι καθαρός. Ώρα για restart."

echo
echo "Το script θα κάνει: systemctl reboot --firmware-setup"
read -r -p "RESTART ΤΩΡΑ; Γράψε YES κεφαλαία: " ANS
if [ "$ANS" = "YES" ]; then
    say "Restart στο firmware setup..."
    systemctl reboot --firmware-setup
else
    warn "Ακυρώθηκε — τρέξε το χειροκίνητα όταν είσαι έτοιμος:"
    echo "  systemctl reboot --firmware-setup"
fi
