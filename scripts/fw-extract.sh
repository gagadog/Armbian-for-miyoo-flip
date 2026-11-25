#!/bin/bash
# Extract the RTL8733BU firmware out of the ButterflyOS image.
set -e
set -o pipefail

SRC="/mnt/c/Users/wang/Downloads/ButterflyOS-Miyoo-Flip-V2-20261125.img.gz"
W=/home/wang/miyoo-build/firmware
IMG="$W/bfos.img"
DEST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device/wifi-firmware"

mkdir -p "$W" "$DEST"

if [ ! -f "$IMG" ]; then
    echo "=== decompressing ($(du -h "$SRC" | cut -f1)) ==="
    zcat "$SRC" > "$IMG"
fi
ls -lh "$IMG"

echo
echo "=== partition table ==="
sfdisk -d "$IMG" 2>/dev/null || fdisk -l "$IMG"

echo
echo "=== mount every partition read-only and look for 8733 firmware ==="
LOOP=$(losetup -fP --show "$IMG")
echo "loop=$LOOP"
ls "${LOOP}"p* 2>/dev/null || true

mkdir -p /mnt/bfos
for part in "${LOOP}"p*; do
    [ -b "$part" ] || continue
    fs=$(blkid -o value -s TYPE "$part" 2>/dev/null || true)
    echo "--- $part ($fs) ---"
    [ -z "$fs" ] && continue
    if mount -o ro "$part" /mnt/bfos 2>/dev/null; then
        echo "  mounted"
        find /mnt/bfos -maxdepth 6 \( -iname '*8733*' -o -iname 'FW_NIC.bin' -o -iname 'AGC_TAB.txt' \
             -o -iname 'PHY_REG*.txt' -o -iname 'Radio?.txt' -o -iname 'TXPWR_LMT.txt' \
             -o -iname 'TxPowerTrack.txt' -o -iname 'wifi_efuse*' -o -iname 'MAC_REG.txt' \
             -o -iname 'wifi_ant_isolation.txt' \) 2>/dev/null | head -40
        umount /mnt/bfos
    else
        echo "  cannot mount"
    fi
done

losetup -d "$LOOP"
echo
echo "done"
