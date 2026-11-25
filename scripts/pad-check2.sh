#!/bin/bash
F=/tmp/dec735.dts
echo "=== pcie node ==="
awk '/pcie@fe260000 \{/{f=1} f{print} f&&/^\t\};/{exit}' "$F" | grep -E 'status|reset-gpios|compatible|phys' | head
echo
echo "=== who mentions gpio0 pin0 (bit 0 of bank0) ==="
grep -n 'gpio0 0x00\|0x00 0x00 0x01' "$F" | head
echo
echo "=== wifi enable pin ==="
grep -n -B3 -A3 'wifi-enable-h' "$F" | head -14
echo
echo "=== button pinctrl groups in source ==="
grep -n -A14 'btn_pins_ctrl:' '/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts' | head -20
echo
echo "=== stick click buttons (source) ==="
grep -n -A4 'BTN_THUMBL\|BTN_THUMBR' '/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts'
