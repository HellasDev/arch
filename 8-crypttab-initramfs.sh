#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 8-crypttab-initramfs.sh
# Δημιουργία ${MNT}/etc/crypttab.initramfs με το LUKS UUID
# (για TPM2 auto-unlock στο initramfs / systemd-ukify).
# ============================================================
. "$(dirname "$0")/_common.sh"

DISK="${DISK:-/dev/nvme0n1}"
CRYPT_PART="${DISK}p2"
MAPPER="/dev/mapper/root"

title "Crypttab initramfs (LUKS UUID)"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."
dev_ok "$CRYPT_PART" || fail "Δεν βρήκα το partition $CRYPT_PART (άλλαξε DISK)."
crypt_ok "$MAPPER"   || fail "Το crypt $MAPPER δεν είναι ανοιχτό (Τρέξε #1)."

# --- 1. UUIDs ----------------------------------------------------
say "Βρίσκω UUIDs..."
LUKS_UUID=$(blkid -s UUID -o value "$CRYPT_PART")
BTRFS_UUID=$(blkid -s UUID -o value "$MAPPER")

# Έλεγχος να μην είναι άδεια
[ -n "$LUKS_UUID" ]  || fail "Δεν βρήκα LUKS UUID από $CRYPT_PART."
[ -n "$BTRFS_UUID" ] || fail "Δεν βρήκα BTRFS UUID από $MAPPER."

echo "LUKS=$LUKS_UUID"
echo "BTRFS=$BTRFS_UUID"

# --- 2. Βασικός έλεγχος UUID format ----------------------------
# 8-4-4-4-12 hex → έλεγχος για LUKS (btrfs είναι παρόμοιο)
if ! echo "$LUKS_UUID" | grep -qE '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
    warn "Το LUKS UUID δεν φαίνεται σωστό μορφής UUID: $LUKS_UUID"
fi

# --- 3. Γράψε το crypttab.initramfs -----------------------------
say "Γράφω ${MNT}/etc/crypttab.initramfs..."
printf 'root UUID=%s none tpm2-device=auto,discard\n' \
    "$LUKS_UUID" \
    > ${MNT}/etc/crypttab.initramfs

chmod 600 ${MNT}/etc/crypttab.initramfs

echo "--- ${MNT}/etc/crypttab.initramfs ---"
cat ${MNT}/etc/crypttab.initramfs

say "ΤΕΛΟΣ #8 — crypttab.initramfs έτοιμο."