#!/bin/bash
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
OUT=/mnt/d/wendang/默认项目/miyoo-flip-dtb/out

echo "=== unmount ==="
sync
umount /mnt/miyoo-boot 2>/dev/null || true
umount /mnt/miyoo-root 2>/dev/null || true
LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -n "$LOOP" ] && losetup -d "$LOOP" || true
sleep 1

echo "=== re-mount and verify ==="
LOOP=$(losetup -fP --show "$IMG")
mount "${LOOP}p1" /mnt/miyoo-boot
mount "${LOOP}p2" /mnt/miyoo-root
echo "--- armbianEnv.txt ---"
cat /mnt/miyoo-boot/armbianEnv.txt
echo "--- dtb ---"
ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb
echo "--- module ---"
ls -l /mnt/miyoo-root/lib/modules/7.3.5-edge-rockchip64/extra/
echo "--- autoload ---"
cat /mnt/miyoo-root/etc/modules-load.d/panel-generic-dsi.conf
echo "--- dtb magic ---"
python3 -c "
d=open('/mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb','rb').read()
print('magic', d[:4].hex(), 'size', len(d))
import re
print('model ok:', b'Miyoo Flip\x00' in d)
print('panel ok:', b'rocknix,generic-dsi\x00' in d)
"
sync
umount /mnt/miyoo-boot
umount /mnt/miyoo-root
losetup -d "$LOOP"
echo "=== verified ==="
