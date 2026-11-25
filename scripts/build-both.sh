#!/bin/bash
# Build both USB-role variants of the Flip DTB against the 7.3.5 tree.
set -e
set -o pipefail
K="$HOME/miyoo-build/src/linux-7.3.5"
S="/mnt/d/wendang/默认项目/miyoo-flip-dtb/src"
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"

cd "$K"
[ -f .config ] && cp .config /tmp/kconfig.keep

cp "$S/rk3566-miyoo-flip-armbian.dts" arch/arm64/boot/dts/rockchip/
cp "$S/rk3566-miyoo-flip-usbhost.dts"  arch/arm64/boot/dts/rockchip/

make ARCH=arm64 allnoconfig >/dev/null
make ARCH=arm64 -j"$(nproc)" \
    rockchip/rk3566-miyoo-flip-armbian.dtb \
    rockchip/rk3566-miyoo-flip-usbhost.dtb 2>&1 | tail -8

[ -f /tmp/kconfig.keep ] && cp /tmp/kconfig.keep .config

cp arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-armbian.dtb "$O/rk3566-miyoo-flip-armbian-7.3.dtb"
cp arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-usbhost.dtb  "$O/rk3566-miyoo-flip-usbhost-7.3.dtb"

echo "=== dr_mode per variant ==="
for f in "$O/rk3566-miyoo-flip-armbian-7.3.dtb" "$O/rk3566-miyoo-flip-usbhost-7.3.dtb"; do
    dtc -I dtb -O dts "$f" -o /tmp/chk.dts 2>/dev/null
    mode=$(awk '/usb@fcc00000 \{/{f=1} f&&/dr_mode/{print $3; exit}' /tmp/chk.dts)
    printf '  %-46s %s  (%s bytes)\n' "$(basename "$f")" "$mode" "$(stat -c %s "$f")"
done
