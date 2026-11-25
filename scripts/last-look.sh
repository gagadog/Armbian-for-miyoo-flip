#!/bin/bash
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
LOOP=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$LOOP" ] && LOOP=$(losetup -fP --show "$IMG")
mountpoint -q /mnt/miyoo-root || mount "${LOOP}p2" /mnt/miyoo-root
H=/mnt/miyoo-root/home/miyoo
echo "=== autostart/antimicrox.desktop ==="
cat "$H/.config/autostart/antimicrox.desktop"
echo "=== onboard autostart ==="
cat "$H/.config/autostart/onboard.desktop"
echo "=== profile head ==="
head -8 "$H/.config/antimicrox/profiles/miyoo-mouse.amgp"
echo "=== desktop icons ==="
ls -l "$H/Desktop"
echo "=== modules-load ==="
ls /mnt/miyoo-root/etc/modules-load.d/
umount /mnt/miyoo-root
losetup -d "$LOOP"
