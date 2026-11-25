#!/bin/bash
# Swap the DTB on the SD card's FAT boot partition (mounted as F: on Windows).
set -e
F=/mnt/f
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
BK="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out/backup-sdcard"

echo "=== before ==="
ls -l "$F/dtb/rockchip/rk3566-miyoo-flip"*.dtb 2>/dev/null || true
mkdir -p "$BK"
cp -f "$F/dtb/rockchip/rk3566-miyoo-flip.dtb" "$BK/rk3566-miyoo-flip.dtb.v3-otg" 2>/dev/null || true

echo "=== copy ==="
cp -f "$O/rk3566-miyoo-flip-armbian-7.3.dtb" "$F/dtb/rockchip/rk3566-miyoo-flip.dtb"
cp -f "$O/rk3566-miyoo-flip-usbhost-7.3.dtb"  "$F/dtb/rockchip/rk3566-miyoo-flip-usbhost.dtb"
sync

echo "=== after ==="
ls -l "$F/dtb/rockchip/rk3566-miyoo-flip"*.dtb

echo "=== verify contents ==="
for f in "$F/dtb/rockchip/rk3566-miyoo-flip.dtb" "$F/dtb/rockchip/rk3566-miyoo-flip-usbhost.dtb"; do
    dtc -I dtb -O dts "$f" -o /tmp/c.dts 2>/dev/null
    mode=$(awk '/usb@fcc00000 \{/{f=1} f&&/dr_mode/{print $3; exit}' /tmp/c.dts)
    ohci=$(awk '/usb@fd840000 \{/{f=1} f&&/status/{print $3; exit}' /tmp/c.dts)
    model=$(grep -m1 'model = ' /tmp/c.dts | cut -d'"' -f2)
    printf '  %-30s model=%-12s dr_mode=%-13s ohci=%s\n' "$(basename "$f")" "$model" "$mode" "$ohci"
done

echo "=== hashes ==="
sha256sum "$F/dtb/rockchip/rk3566-miyoo-flip.dtb" "$O/rk3566-miyoo-flip-armbian-7.3.dtb"
echo "=== fdtfile ==="
grep fdtfile "$F/armbianEnv.txt"
