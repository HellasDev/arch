#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 12-system-services.sh
# zram, resolv.conf, enable services, mask networkd, bootctl.
# ============================================================
. "$(dirname "$0")/_common.sh"

title "System services + bootctl"

mount_ok || fail "Το ${MNT} δεν είναι montarismeno."

# --- 1. zram-generator -------------------------------------------
say "Γράφω ${MNT}/etc/systemd/zram-generator.conf..."
cat > ${MNT}/etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF
echo "--- ${MNT}/etc/systemd/zram-generator.conf ---"
cat ${MNT}/etc/systemd/zram-generator.conf

# --- 2. resolv.conf ----------------------------------------------
say "Symlink /run/systemd/resolve/stub-resolv.conf..."
run arch-chroot ${MNT} ln -sf \
    /run/systemd/resolve/stub-resolv.conf \
    /etc/resolv.conf

# --- 3. Enable services ------------------------------------------
# ΣΗΜΕΙΩΣΗ: Εδώ ενεργοποιούμε ΜΟΝΟ τα βασικά system services.
# Τα polkit / gnome-keyring / xdg-desktop-portals / κ.λπ.
# ενεργοποιούνται ΜΕΤΑ το reboot με ξεχωριστό script (αυτόματα
# μέσω DBus στο session του niri).
say "Ενεργοποίηση services..."
run systemctl --root ${MNT} enable \
    systemd-resolved \
    systemd-timesyncd \
    NetworkManager \
    sshd \
    systemd-boot-update \
    bluetooth \
    ufw \
    snapper-timeline.timer \
    snapper-cleanup.timer

# --- 4. Mask networkd ---------------------------------------------
say "Mask systemd-networkd..."
run systemctl --root ${MNT} mask systemd-networkd

# --- 5. Bootctl install --------------------------------------------
say "bootctl install --esp-path=/efi..."
run arch-chroot -S ${MNT} bootctl install --esp-path=/efi

say "ΤΕΛΟΣ #12 — services και bootctl έτοιμα."
