#!/bin/bash
D="/mnt/d/wendang/默认项目/miyoo-flip-dtb/src"
V="/mnt/d/wendang/默认项目/miyoo-flip-dtb/../.."
echo "=== our DTS: usb nodes ==="
grep -n 'usb@\|usbdrd\|dwc3\|usb2phy\|usb_host\|dr_mode\|extcon\|role-switch\|vbus' "$D/rk3566-miyoo-flip-armbian.dts" | head -60
