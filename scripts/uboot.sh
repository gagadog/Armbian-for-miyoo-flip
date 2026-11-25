#!/bin/bash
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
echo "=== sector 64 (idbloader) ==="
dd if="$IMG" bs=512 skip=64 count=1 status=none | xxd | head -2
echo "=== sector 16384 (u-boot.itb) ==="
dd if="$IMG" bs=512 skip=16384 count=8 status=none | xxd | head -2
echo
echo "=== strings identifying u-boot board ==="
dd if="$IMG" bs=512 skip=16384 count=4096 status=none > /tmp/uboot.itb
ls -l /tmp/uboot.itb
for s in quartz64 quartz64-a rk3566-rock-3 anbernic rk3566; do
    c=$(grep -ac "$s" /tmp/uboot.itb 2>/dev/null || echo 0)
    echo "$s: $c"
done
echo
echo "=== u-boot version strings ==="
strings -n 6 /tmp/uboot.itb | grep -iE 'U-Boot 20|quartz64' | head -8
