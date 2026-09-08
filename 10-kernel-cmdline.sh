#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 10-kernel-cmdline.sh
# Δημιουργία ${MNT}/etc/kernel/cmdline από τα δεδομένα του #9.
# ============================================================
. "$(dirname "$0")/_common.sh"

DISK="${DISK:-/dev/nvme0n1}"
ENVFILE="${MNT}/etc/install.env"
CMDFILE="${MNT}/etc/kernel/cmdline"

title "Kernel cmdline (LUKS + Btrfs + resume)"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."

# --- 1. Φόρτωσε τα δεδομένα από το #9 --------------------------
[ -f "$ENVFILE" ] || fail "Δεν βρήκα $ENVFILE. Τρέξε πρώτα το #9."
. "$ENVFILE"

# --- 2. Ξανά-έλεγχος ότι όλα είναι γεμάτα -----------------------
for var in LUKS_UUID BTRFS_UUID RESUME_OFFSET; do
    [ -n "${!var:-}" ] || fail "Η μεταβλητή $var είναι άδεια (λόγω #9)."
done

say "Επαληθεύω ξανά ότι το filesystem του swap == BTRFS_UUID..."
SWAPFILE_FS=$(findmnt -no UUID -T ${MNT}/swap/swapfile)
echo "BTRFS=$BTRFS_UUID  |  SWAPFILE_FS=$SWAPFILE_FS"
[ "$SWAPFILE_FS" = "$BTRFS_UUID" ] || fail "Αναντιστοιχία: SWAPFILE_FS != BTRFS_UUID."

# --- 3. Γράψε το cmdline -----------------------------------------
say "Γράφω $CMDFILE..."
mkdir -p ${MNT}/etc/kernel
printf 'rd.luks.uuid=%s root=UUID=%s rootflags=subvol=@ resume=UUID=%s resume_offset=%s rw quiet\n' \
    "$LUKS_UUID" \
    "$BTRFS_UUID" \
    "$BTRFS_UUID" \
    "$RESUME_OFFSET" \
    > "$CMDFILE"

echo "--- $CMDFILE ---"
cat "$CMDFILE"

say "ΤΕΛΟΣ #10 — Kernel cmdline έτοιμο."