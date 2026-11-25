#!/bin/bash
set -e
IMG="/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img"
LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
if [ -z "$LOOP" ]; then
    LOOP=$(losetup -fP --show "$IMG")
fi
echo "loop=$LOOP"
ls -l "${LOOP}"p1 "${LOOP}"p2
mkdir -p /mnt/miyoo-boot /mnt/miyoo-root
mount | grep -q /mnt/miyoo-boot || mount "${LOOP}p1" /mnt/miyoo-boot
mount | grep -q /mnt/miyoo-root || mount "${LOOP}p2" /mnt/miyoo-root
echo "=== /boot (FAT) ==="
ls -l /mnt/miyoo-boot
echo
echo "=== /boot/dtb/rockchip (first 20) ==="
ls /mnt/miyoo-boot/dtb/rockchip 2>/dev/null | head -20
echo "count: $(ls /mnt/miyoo-boot/dtb/rockchip 2>/dev/null | wc -l)"
echo
echo "=== armbianEnv.txt ==="
cat /mnt/miyoo-boot/armbianEnv.txt 2>/dev/null
echo
echo "=== extlinux ==="
cat /mnt/miyoo-boot/extlinux/extlinux.conf 2>/dev/null
