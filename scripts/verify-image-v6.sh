#!/bin/bash
# Final content check of the packed image.
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
B=/mnt/miyoo-boot
REL=7.3.5-edge-rockchip64

mountpoint -q "$R" && umount "$R" || true
mountpoint -q "$B" && umount "$B" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p1" "$B"
mount "${L}p2" "$R"

echo "=== identity ==="
echo "  hostname: $(cat "$R/etc/hostname")"
grep -E '^(BOARD|BOARD_NAME)=' "$R/etc/armbian-release" | sed 's/^/  /'

echo "=== boot ==="
grep -E '^(fdtfile|extraargs)' "$B/armbianEnv.txt" | sed 's/^/  /'
ls "$B/dtb/rockchip/" | grep miyoo | sed 's/^/  dtb: /'

echo "=== modules ==="
ls "$R/lib/modules/$REL/extra/" 2>/dev/null | sed 's/^/  extra: /'
ls -l "$R/lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko" 2>/dev/null | awk '{print "  wifi: "$5" bytes"}'
echo "  modules-load.d: $(ls "$R/etc/modules-load.d/" | tr '\n' ' ')"
echo "  modprobe.d 8733: $(ls "$R/etc/modprobe.d/" | grep 8733 | tr '\n' ' ')"

echo "=== services ==="
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|lid|usb-gadget|dnsmasq|ssh|rgds' | sed 's/^/  /'
echo "  rgds-pad2key -> $(readlink "$R/etc/systemd/system/rgds-pad2key.service" 2>/dev/null || echo 'not masked')"

echo "=== desktop/autostart ==="
for f in "$R"/home/miyoo/.config/autostart/*.desktop; do
    echo "  $(basename "$f"): $(grep -m1 '^Exec=' "$f" | cut -c6-)"
done
ls "$R/home/miyoo/Desktop/" | sed 's/^/  icon: /'

echo "=== at-spi / onboard ==="
grep -c '^Package: python3-pyatspi$' "$R/var/lib/dpkg/status" 2>/dev/null | sed 's/^/  pyatspi pkgs: /'
ls -l "$R/usr/bin/onboard" 2>/dev/null | awk '{print "  onboard: "$5" bytes"}'
ls -l "$R/usr/bin/antimicrox" 2>/dev/null | awk '{print "  antimicrox: "$5" bytes"}'

echo "=== ssh ==="
wc -c "$R/home/miyoo/.ssh/authorized_keys" 2>/dev/null | awk '{print "  authorized_keys: "$1" bytes"}'

echo "=== disk ==="
df -h "$R" | tail -1

sync
umount "$B"
umount "$R"
losetup -d "$L"
echo VERIFY_DONE
