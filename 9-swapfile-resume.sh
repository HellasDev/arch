#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 9-swapfile-resume.sh
# Βρίσκει LUKS_UUID, BTRFS_UUID, RESUME_OFFSET από το swapfile,
# και ΕΠΑΛΗΘΕΥΕΙ ότι το swap filesystem == BTRFS_UUID.
# Αποθηκεύει τα δεδομένα σε ${MNT}/etc/install.env για το #10.
# ============================================================
. "$(dirname "$0")/_common.sh"

DISK="${DISK:-/dev/nvme0n1}"
CRYPT_PART="${DISK}p2"
MAPPER="/dev/mapper/root"
SWAPFILE="${MNT}/swap/swapfile"
ENVFILE="${MNT}/etc/install.env"

title "Swapfile / RESUME_OFFSET / UUIDs"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."
crypt_ok "$MAPPER"      || fail "Το crypt $MAPPER δεν είναι ανοιχτό."
[ -f "$SWAPFILE" ]    || fail "Δεν βρήκα $SWAPFILE. Χρησιμοποιείς Btrfs subvol=@swap;"

# --- 1. UUIDs -----------------------------------------------------
say "Βρίσκω LUKS UUID..."
LUKS_UUID=$(blkid -s UUID -o value "$CRYPT_PART")
[ -n "$LUKS_UUID" ] || fail "Δεν βρήκα LUKS UUID από $CRYPT_PART."

say "Βρίσκω BTRFS UUID..."
BTRFS_UUID=$(blkid -s UUID -o value "$MAPPER")
[ -n "$BTRFS_UUID" ] || fail "Δεν βρήκα BTRFS UUID από $MAPPER."

# --- 2. RESUME_OFFSET ---------------------------------------------
say "RESUME_OFFSET από το swapfile..."
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r "$SWAPFILE")
echo "RESUME_OFFSET=$RESUME_OFFSET"
echo "$RESUME_OFFSET" | grep -qE '^[0-9]+$' || \
    fail "το RESUME_OFFSET δεν είναι αριθμός: $RESUME_OFFSET"

# --- 3. ΕΠΑΛΗΘΕΥΣΗ: swap filesystem == BTRFS_UUID -----------------
say "Έλεγχος ότι το filesystem του swap == BTRFS_UUID..."
SWAPFILE_FS=$(findmnt -no UUID -T "$SWAPFILE")
[ -n "$SWAPFILE_FS" ] || fail "Δεν βρήκα UUID για το filesystem του swap."

echo "BTRFS=$BTRFS_UUID"
echo "SWAPFILE_FS=$SWAPFILE_FS"
[ "$SWAPFILE_FS" = "$BTRFS_UUID" ] || fail "Αναντιστοιχία! SWAPFILE_FS != BTRFS_UUID."

say "OK: αντιστοιχούν. Προχωράω..."

# --- 4. Αποθήκευση state -------------------------------------------
say "Αποθήκευση στο $ENVFILE..."
cat > "$ENVFILE" << EOF
LUKS_UUID=$LUKS_UUID
BTRFS_UUID=$BTRFS_UUID
RESUME_OFFSET=$RESUME_OFFSET
EOF
chmod 600 "$ENVFILE"

echo "--- $ENVFILE ---"
cat "$ENVFILE"

say "ΤΕΛΟΣ #9 — Δεδομένα έτοιμα για το #10."