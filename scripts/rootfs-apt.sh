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
echo "=== apt sources.d ==="
ls -l /mnt/miyoo-root/etc/apt/sources.list.d/ 2>/dev/null
for f in /mnt/miyoo-root/etc/apt/sources.list.d/*; do
    [ -f "$f" ] || continue
    echo "--- $f"
    cat "$f"
done
echo
echo "=== /etc/apt/sources.list ==="
cat /mnt/miyoo-root/etc/apt/sources.list 2>/dev/null || echo "(missing)"
echo
echo "=== keyrings ==="
ls -l /mnt/miyoo-root/etc/apt/keyrings/ /mnt/miyoo-root/usr/share/keyrings/ 2>/dev/null | head -20
echo
echo "=== release info ==="
cat /mnt/miyoo-root/etc/os-release | head -5
echo
echo "=== arm64 exec test ==="
chroot /mnt/miyoo-root /bin/echo "hello from $(uname -m) container rootfs"
echo
echo "=== free space ==="
df -h /mnt/miyoo-root
