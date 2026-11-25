#!/bin/bash
R=/mnt/miyoo-root
B=/mnt/miyoo-boot
echo "=== mounts under $R ==="
mount | grep "$R" | sed 's/^/  /'
echo
for m in $(mount | awk -v p="$R" '$3 ~ p {print $3}' | sort -r); do
    echo "umount $m"
    umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
done
for m in $(mount | awk -v p="$B" '$3 ~ p {print $3}' | sort -r); do
    echo "umount $m"
    umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
done
sleep 1
echo
echo "=== remaining ==="
mount | grep -E 'miyoo-root|miyoo-boot' | sed 's/^/  /' || echo "  none"
echo
echo "=== who holds it ==="
fuser -vm "$R" 2>&1 | head -5 || true
echo
echo "=== loops ==="
losetup -a | sed 's/^/  /'
