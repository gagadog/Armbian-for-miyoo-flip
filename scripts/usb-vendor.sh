#!/bin/bash
V=/home/wang/miyoo-build/miyoo_flip.dts
if [ ! -f "$V" ]; then
    V="/mnt/c/Users/wang/AppData/Local/Temp/opencode/miyoo/miyoo_flip.dts"
fi
echo "using: $V"
echo "=== usb / phy / dr_mode ==="
grep -n 'usbdrd\|dwc3\|usb2phy\|usb_host\|dr_mode\|extcon\|otg\|vbus\|ohci\|ehci' "$V" | head -60
