#!/bin/bash
# Mount the image, restore the kernel build config, install the updated DTB and
# modules, verify, then unmount.
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
K=/home/wang/miyoo-build/src/linux-7.3.5
OUT="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
REL=7.3.5-edge-rockchip64

LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$LOOP" ] && LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/miyoo-boot /mnt/miyoo-root
mountpoint -q /mnt/miyoo-boot || mount "${LOOP}p1" /mnt/miyoo-boot
mountpoint -q /mnt/miyoo-root || mount "${LOOP}p2" /mnt/miyoo-root
echo "mounted on ${LOOP}p1 ${LOOP}p2"

echo "=== restore kernel build config ==="
cp /mnt/miyoo-boot/config-$REL "$K/.config"
( cd "$K" && ./scripts/config --file .config --set-str LOCALVERSION "-edge-rockchip64" \
  && make -s ARCH=arm64 olddefconfig >/dev/null && grep '^CONFIG_LOCALVERSION=' .config )

echo "=== install ==="
bash "/mnt/d/wendang/默认项目/miyoo-flip-dtb/scripts/install.sh"

echo "=== kernelrelease sanity ==="
( cd "$K" && make -s ARCH=arm64 kernelrelease )

echo "=== unmount ==="
sync
umount /mnt/miyoo-boot
umount /mnt/miyoo-root
losetup -d "$LOOP"
echo DONE
