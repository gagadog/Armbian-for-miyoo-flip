#!/bin/bash
set -e
IMG=/home/wang/miyoo-build/firmware/bfos.img
LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$LOOP" ] && LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/bfos1 /mnt/bfos2
mountpoint -q /mnt/bfos1 || mount -o ro "${LOOP}p1" /mnt/bfos1
mountpoint -q /mnt/bfos2 || mount -o ro "${LOOP}p2" /mnt/bfos2 2>/dev/null || true

echo "=== p1 (system) ==="
ls -la /mnt/bfos1 | head -20
echo
echo "=== p2 (storage) ==="
ls -la /mnt/bfos2 2>/dev/null | head -20
echo
echo "=== big files in p1 ==="
find /mnt/bfos1 -maxdepth 2 -type f -size +10M -exec ls -lh {} \; 2>/dev/null | head -10
echo
echo "=== unsquashfs available? ==="
which unsquashfs || echo "  missing"
