#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 4-reflector-mirrorlist.sh
# Ενημερώνει το mirrorlist με τα καλύτερα mirrors από Ελλάδα.
# Τρέχει ΑΥΤΟΜΑΤΑ μέσα στο chroot (δεν χρειάζεται να το κάνεις εσύ).
# ============================================================
. "$(dirname "$0")/_common.sh"

rinchroot "$0"

title "Reflector — mirrorlist από Ελλάδα"

[ -f /etc/pacman.d/mirrorlist ] || fail "Δεν βρήκα mirrorlist."

run reflector \
    --country Greece \
    --latest 10 \
    --protocol https \
    --sort rate \
    --save /etc/pacman.d/mirrorlist

say "ΤΕΛΟΣ #4 — Mirrorlist ενημερώθηκε."