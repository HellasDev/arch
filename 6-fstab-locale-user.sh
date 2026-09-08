#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 6-fstab-locale-user.sh
# fstab, locale, firstboot, hosts, και δημιουργία χρήστη.
# Τα host-μέρη τρέχουν στο live, τα chroot-μέρη μπαίνουν μόνα τους.
# ============================================================
. "$(dirname "$0")/_common.sh"

host_part() {
    say "genfstab..."
    run genfstab -U "${MNT}" >> "${MNT}/etc/fstab"
    echo "--- ${MNT}/etc/fstab ---"
    cat "${MNT}/etc/fstab"

    say "locale.gen (en_US + el_GR)..."
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "${MNT}/etc/locale.gen"
    sed -i 's/^#el_GR.UTF-8 UTF-8/el_GR.UTF-8 UTF-8/' "${MNT}/etc/locale.gen"

    say "systemd-firstboot (prompt)..."
    run systemd-firstboot --root="${MNT}" --prompt

    say "locale.conf..."
    printf 'LANG=en_US.UTF-8\n' > "${MNT}/etc/locale.conf"

    say "hosts..."
    cat > "${MNT}/etc/hosts" << 'EOF'
127.0.0.1        localhost
::1              localhost
127.0.1.1        asus.localdomain asus
EOF
}

chroot_part() {
    say "locale-gen (μέσα στο chroot)..."
    run locale-gen

    say "Έλεγχος ομάδας 'users':"
    run getent group users

    say "Δημιουργία χρήστη 'hellasdev'..."
    run useradd \
        -m \
        -G wheel,users,storage,audio,video,input \
        -s /bin/bash \
        hellasdev

    say "Κωδικός για τον χρήστη hellasdev:"
    run passwd hellasdev

    say "Sudo χωρίς κωδικό για τους χρήστες wheel..."
    enable_wheel_nopasswd
}

# ============ ΚΥΡΙΑ ΛΟΓΙΚΗ ============
if is_chroot; then
    # Είμαστε ήδη μέσα σε real chroot (re-entry από rinchroot):
    # κάνε ΜΟΝΟ το chroot τμήμα.
    title "CHROOT ΜΕΡΟΣ (#6)"
    chroot_part
else
    # Host (live): κάνε το host τμήμα.
    title "#6 — FSTAB + LOCALE + HOSTS (host)"
    mount_ok || fail "Το ${MNT} δεν είναι montarismeno."
    mkdir -p "${MNT}/etc"
    [ -f "${MNT}/etc/locale.gen" ] || printf '#en_US.UTF-8 UTF-8\n#el_GR.UTF-8 UTF-8\n' > "${MNT}/etc/locale.gen"
    host_part

    # Live: μπαίνω μόνος μου στο chroot για το chroot τμήμα.
    say "Μπαίνω στο chroot για το τμήμα chroot..."

    rinchroot "$0"

fi

say "ΤΕΛΟΣ #6 — fstab, locale, hosts και χρήστης έτοιμο."
