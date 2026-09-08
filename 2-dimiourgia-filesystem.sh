#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 2-δημιουργία-συστήματος-αρχείων.sh
# FAT32 (ESP) + Btrfs πάνω από το LUKS, subvolumes, mounts,
# και swapfile.
# ΕΚΤΕΛΕΙΤΑΙ μετά το script #1 (με το root crypt ΑΝΟΙΧΤΟ).
# ============================================================
. "$(dirname "$0")/_common.sh"

DISK="${DISK:-/dev/nvme0n1}"
ESP_PART="${DISK}p1"
MAPPER="/dev/mapper/root"

BTRFS_OPTS="noatime,compress=zstd:3,ssd,discard=async,space_cache=v2"
SWAP_SIZE="${SWAP_SIZE:-32g}"

title "Σύστημα αρχείων — FAT32 + Btrfs + subvolumes + swap"

crypt_ok "$MAPPER" || fail "Το crypt '$MAPPER' ΔΕΝ είναι ανοιχτό. Τρέξε πρώτα το script #1."
dev_ok "$ESP_PART" || fail "Το ESP '$ESP_PART' δεν υπάρχει."

# --- 1. Συστήματα αρχείων -----------------------------------
say "ESP FAT32..."
run mkfs.fat -F32 -n ESP "$ESP_PART"

say "Btrfs πάνω στο LUKS ($MAPPER)..."
run mkfs.btrfs -f -L root "$MAPPER"

# --- 2. Subvolumes -------------------------------------------
say "Δημιουργία subvolumes..."
run mount "$MAPPER" ${MNT}

for sub in @ @home @snapshots @srv @log @cache @tmp @swap; do
    btrfs subvolume create "${MNT}/$sub"
done

say "Λίστα subvolumes:"
run btrfs subvolume list ${MNT}

run umount ${MNT}

# --- 3. Mount -------------------------------------------------
say "Montarisma με options: $BTRFS_OPTS"
run mount -o "${BTRFS_OPTS},subvol=@" "$MAPPER" ${MNT}

mkdir -p ${MNT}/{home,srv,var/log,var/cache,var/tmp,efi,.snapshots,swap}

run mount -o "${BTRFS_OPTS},subvol=@home"      "$MAPPER" ${MNT}/home
run mount -o "${BTRFS_OPTS},subvol=@snapshots" "$MAPPER" ${MNT}/.snapshots
run mount -o "${BTRFS_OPTS},subvol=@srv"       "$MAPPER" ${MNT}/srv
run mount -o "${BTRFS_OPTS},subvol=@log"       "$MAPPER" ${MNT}/var/log
run mount -o "${BTRFS_OPTS},subvol=@cache"     "$MAPPER" ${MNT}/var/cache
run mount -o "${BTRFS_OPTS},subvol=@tmp"       "$MAPPER" ${MNT}/var/tmp
run mount -o "${BTRFS_OPTS},subvol=@swap"      "$MAPPER" ${MNT}/swap

run mount "$ESP_PART" ${MNT}/efi

say "findmnt ${MNT}:"
run findmnt ${MNT} || true

# --- 4. Swapfile ----------------------------------------------
say "Δημιουργία swapfile ${SWAP_SIZE}..."
run btrfs filesystem mkswapfile \
    --size "$SWAP_SIZE" \
    --uuid clear \
    ${MNT}/swap/swapfile

run swapon ${MNT}/swap/swapfile

say "swapon --show:"
run swapon --show

say "ΤΕΛΟΣ #2 — Ο δίσκος είναι έτοιμος για την εγκατάσταση."