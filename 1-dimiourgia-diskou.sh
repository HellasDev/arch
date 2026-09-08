#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 1-δημιουργία-δίσκου.sh
# Δημιουργία δίσκου: διαμερίσματα + κρυπτογράφηση LUKS.
# ΕΚΤΕΛΕΙΤΑΙ ΑΠΟ το live USB, όχι μέσα σε chroot.
# ============================================================
. "$(dirname "$0")/_common.sh"

# --- Δίσκος που θα χρησιμοποιηθεί (άλλαξε αν χρειάζεται) ---
DISK="${DISK:-/dev/nvme0n1}"
CRYPTO_NAME="root"

title "Δημιουργία δίσκου — Pre-flight"

timedatectl set-ntp true 2>/dev/null || warn "Δεν μπόρεσα να ενεργοποιήσω το NTP"
timedatectl

say "Διεπαφές δικτύου:"
ip -br addr || true
say "Ping archlinux.org:"
ping -c 3 archlinux.org || warn "Δεν έχουμε σύνδεση στο internet"

say "Εικόνα δίσκου:"
lsblk -o NAME,SIZE,TYPE,MODEL,TRAN || true

# --- ΕΠΙΒΕΒΑΙΩΣΗ ----------------------------------------------
echo
warn "Το παρακάτω σχήμα θα ΚΑΘΑΡΙΣΕΙ ολόκληρο τον δίσκο: $DISK"
read -r -p "ΣΙΓΟΥΡΟ; Για να συνεχίσεις γράψε YES κεφαλαία: " ANSWER
if [ "$ANSWER" != "YES" ]; then
    fail "Πράξη ακυρώθηκε (χρειαζόταν ακριβώς: YES)"
fi

# --- Διαμερίσματα ----------------------------------------------
say "Καθαρισμός δίσκου σε GPT..."
run sgdisk -Z "$DISK"

say "Δημιουργία διαμερισμάτων (esp + cryptroot)..."
run sgdisk \
    -n1:0:+1G -t1:ef00 -c1:esp \
    -n2:0:0 -t2:8309 -c2:cryptroot \
    "$DISK"

run partprobe -s "$DISK"
sleep 2
lsblk "$DISK"

# --- LUKS ------------------------------------------------------
ESP_PART="${DISK}p1"
CRYPT_PART="${DISK}p2"

say "Μορφοποίηση LUKS του $CRYPT_PART (luks2, argon2id)..."
echo "ΣΗΜΕΙΩΣΗ: Όταν σε ρωτήσει για 'YES' πάτησε YES κεφαλαία και άντε."
echo "      Θα ζητήσει τον κωδικό ΔΥΟ φορές."
run cryptsetup luksFormat \
    --type luks2 \
    --pbkdf argon2id \
    "$CRYPT_PART"

say "Άνοιγμα του LUKS διαμερίσματος ως '$CRYPTO_NAME'..."
run cryptsetup open "$CRYPT_PART" "$CRYPTO_NAME"

say "Έγινε! Ο κρυπτογραφημένος όγκος: /dev/mapper/$CRYPTO_NAME"
lsblk /dev/mapper/"$CRYPTO_NAME" || true