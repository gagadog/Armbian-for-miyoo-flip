#!/bin/bash
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$LOOP" ] && LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/miyoo-boot /mnt/miyoo-root
mountpoint -q /mnt/miyoo-boot || mount "${LOOP}p1" /mnt/miyoo-boot
mountpoint -q /mnt/miyoo-root || mount "${LOOP}p2" /mnt/miyoo-root
echo "loop=$LOOP"
echo
echo "=== free space on rootfs ==="
df -h /mnt/miyoo-root
echo
echo "=== sources.list ==="
cat /mnt/miyoo-root/etc/apt/sources.list 2>/dev/null
ls /mnt/miyoo-root/etc/apt/sources.list.d/ 2>/dev/null
for f in /mnt/miyoo-root/etc/apt/sources.list.d/*; do echo "--- $f"; cat "$f"; done 2>/dev/null
echo
echo "=== installed desktop-ish packages ==="
ls /mnt/miyoo-root/usr/share/xsessions/ 2>/dev/null || echo "no xsessions"
echo
echo "=== apt arch ==="
cat /mnt/miyoo-root/etc/apt/sources.list.d/*.sources 2>/dev/null | head -20
