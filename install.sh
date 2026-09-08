#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install.sh
# ΕΚΤΕΛΕΙΤΑΙ ΑΠΟ ΤΟ LIVE USB.
# Τρέχει αυτόματα όλα τα scripts εγκατάστασης με τη σειρά
# (#1 έως #13). Το #14 (session services) τρέχει ΜΕΤΑ το
# reboot, μέσα στο νέο σύστημα.
# ============================================================
. "$(dirname "$0")/_common.sh"

SCRIPTS=(
    1-dimiourgia-diskou.sh
    2-dimiourgia-filesystem.sh
    3-pacstrap-base.sh
    4-reflector-mirrorlist.sh
    5-pacstrap-gui.sh
    6-fstab-locale-user.sh
    7-pacman-config.sh
    8-crypttab-initramfs.sh
    9-swapfile-resume.sh
    10-kernel-cmdline.sh
    11-mkinitcpio.sh
    12-system-services.sh
    13-verify-unmount-reboot.sh
)

title "ΑΥΤΟΜΑΤΗ ΕΓΚΑΤΑΣΤΑΣΗ (live USB)"

MYSELF="$(basename "$0")"

# --- Ασφάλεια: μόνο από live USB / κανονικό σύστημα, ΟΧΙ chroot ---
if is_chroot; then
    fail "Το $MYSELF τρέχει ΜΟΝΟ από το live USB.
    Είσαι τώρα σε chroot ($MNT); Κάνε exit και ξαναδοκίμασε."
fi

# --- Έλεγχος ότι όλα τα scripts υπάρχουν --------------------------
for s in "${SCRIPTS[@]}"; do
    [ -f "$s" ] || fail "Δεν βρήκα το script: $s"
    [ -x "$s" ] || chmod +x "$s"
done

# --- Επιβεβαίωση ----------------------------------------------------
echo
warn "Θα τρέξουν ${#SCRIPTS[@]} scripts:"
for s in "${SCRIPTS[@]}"; do printf '   - %s\n' "$s"; done
echo
read -r -p "ΣΙΓΟΥΡΟ; Γράψε YES κεφαλαία για εκκίνηση: " ANSWER
if [ "$ANSWER" != "YES" ]; then
    fail "Ακυρώθηκε (χρειαζόταν: YES)"
fi

# --- Εκτέλεση με τη σειρά -------------------------------------------
START=$(date +%s)
for s in "${SCRIPTS[@]}"; do
    echo
    say "########## Εκτελώ: $s ##########"
    ./"$s"
    echo
    say "########## Ολοκληρώθηκε: $s ##########"
done

END=$(date +%s)
echo
title "ΕΓΚΑΤΑΣΤΑΣΗ ΟΛΟΚΛΗΡΩΘΗΚΕ σε $((END - START)) δευτερόλεπτα"

echo
echo "Επόμενα βήματα:"
echo "  1) Ο υπολογιστής θα κάνει reboot στο firmware setup"
echo "  2) Μετά το login στο niri τρέξε: ./14-session-services.sh"
echo "  3) Και: sudo ufw enable  (αν δεν έχει ήδη γίνει)"