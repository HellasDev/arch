#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 7-pacman-διαμόρφωση.sh
# Pacman: Color, ParallelDownloads=8, ILoveCandy, και multilib.
# (Επεξεργασία του ${MNT}/etc/pacman.conf από το live/host.)
# ============================================================
. "$(dirname "$0")/_common.sh"

PCONF="${MNT}/etc/pacman.conf"

title "Διαμόρφωση Pacman"

[ -f "$PCONF" ] || fail "Δεν βρήκα $PCONF. Ίσως δεν τρέχει ακόμα το #3 (pacstrap)."
mount_ok || fail "Το ${MNT} δεν είναι montarismeno."

say "Color..."
sed -i 's/^#Color/Color/' "$PCONF"

say "ParallelDownloads = 8..."
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 8/' "$PCONF"

say "ILoveCandy..."
grep -q '^ILoveCandy' "$PCONF" || \
    sed -i '/^Color/a ILoveCandy' "$PCONF"

say "Ξε-σχολίασε multilib..."
sed -i 's/^#\[multilib\]$/[multilib]/' "$PCONF"
sed -i '/^\[multilib\]$/{n;s/^#Include/Include/}' "$PCONF"

say "--- Τελικό ${MNT}/etc/pacman.conf (άνοιγμα μέσα) ---"
echo ">>> Color/Parallel/ILoveCandy/Include <<<"
grep -nE '^(Color|ILoveCandy|ParallelDownloads|\[multilib\]|Include)' "$PCONF" || true

say "ΤΕΛΟΣ #7 — Pacman ρυθμισμένο."