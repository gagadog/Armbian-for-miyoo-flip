#!/bin/bash
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
L=$(losetup -fP --show "$IMG")
mkdir -p /mnt/miyoo-root
mount "${L}p2" /mnt/miyoo-root
bash "/mnt/d/wendang/默认项目/miyoo-flip-dtb/scripts/gpu-check.sh"
sync
umount /mnt/miyoo-root
losetup -d "$L"
