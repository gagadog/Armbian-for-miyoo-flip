#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5/arch/arm64/boot/dts/rockchip
echo "=== mainline rk3566 handhelds: usb_host0_xhci config ==="
for f in rk3566-powkiddy-x55.dts rk3566-anbernic-rg353x.dtsi rk3566-anbernic-rgxx3.dtsi rk3566-powkiddy-rk2023.dtsi rk3566-rock-3c.dts; do
  [ -f "$K/$f" ] || continue
  echo "--- $f"
  awk '/&usb_host0_xhci/,/^};/' "$K/$f"
  awk '/&usb_host0_ohci/,/^};/' "$K/$f"
done
echo
echo "=== vbus-supply / otg_switch anywhere in rockchip dts ==="
grep -rn 'vbus-supply\|otg_switch' "$K" | head -12
echo
echo "=== our DTS otg_switch ==="
grep -n 'otg_switch\|vbus-supply' "/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts"
echo "=== vendor DTS otg_switch refs ==="
grep -n 'otg_switch\|vbus-supply' "/mnt/c/Users/wang/AppData/Local/Temp/opencode/miyoo/miyoo_flip.dts"
