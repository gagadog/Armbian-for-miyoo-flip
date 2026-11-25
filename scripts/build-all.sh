#!/bin/bash
# Build every Flip DTB variant against the 7.3.5 tree and report dr_mode /
# which input block each one carries.
set -e
set -o pipefail
. "$(dirname "$0")/env.sh"
S="$ROOT/src"
O="$ROOT/out"

cd "$K"
[ -f .config ] && cp .config /tmp/kconfig.keep

for f in rk3566-miyoo-flip-armbian.dts rk3566-miyoo-flip-usbhost.dts rk3566-miyoo-flip-joypad.dts; do
    cp "$S/$f" arch/arm64/boot/dts/rockchip/
done

make ARCH=arm64 allnoconfig >/dev/null
make ARCH=arm64 -j"$(nproc)" \
    rockchip/rk3566-miyoo-flip-armbian.dtb \
    rockchip/rk3566-miyoo-flip-usbhost.dtb \
    rockchip/rk3566-miyoo-flip-joypad.dtb 2>&1 | tail -12

[ -f /tmp/kconfig.keep ] && cp /tmp/kconfig.keep .config

cp arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-armbian.dtb "$O/rk3566-miyoo-flip-armbian-7.3.dtb"
cp arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-usbhost.dtb  "$O/rk3566-miyoo-flip-usbhost-7.3.dtb"
cp arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-joypad.dtb   "$O/rk3566-miyoo-flip-joypad-7.3.dtb"

echo "=== variants ==="
for f in "$O"/rk3566-miyoo-flip-*-7.3.dtb; do
    dtc -I dtb -O dts "$f" -o /tmp/v.dts 2>/dev/null
    mode=$(awk '/usb@fcc00000 \{/{f=1} f&&/dr_mode/{print $3; exit}' /tmp/v.dts)
    if grep -q 'rocknix-singleadc-joypad' /tmp/v.dts; then pad=joypad; else pad=gpio-keys; fi
    printf '  %-42s %-12s %-10s %s bytes\n' "$(basename "$f")" "$mode" "$pad" "$(stat -c %s "$f")"
done
