#!/bin/bash
R=/mnt/miyoo-root
B=/mnt/miyoo-boot
for m in $(mount | awk -v p="$R" '$3 ~ p {print $3}' | sort -r) \
         $(mount | awk -v p="$B" '$3 ~ p {print $3}' | sort -r); do
    umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
done
sleep 1
echo "remaining miyoo mounts: $(mount | grep -cE 'miyoo-root|miyoo-boot')"
