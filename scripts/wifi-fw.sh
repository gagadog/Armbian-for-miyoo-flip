#!/bin/bash
D=/home/wang/miyoo-build/rtl8733bu/tip
echo "=== firmware names requested by driver ==="
grep -rhoE '"[a-zA-Z0-9_./-]*\.(bin|map|txt)"' "$D" 2>/dev/null | sort -u | head -30
echo
echo "=== request_firmware call sites ==="
grep -rn 'request_firmware' "$D" | head -10
echo
echo "=== image: existing rtl8733 firmware? ==="
ls /mnt/miyoo-root/lib/firmware/ 2>/dev/null | head -20
find /mnt/miyoo-root/lib/firmware -iname '*8733*' 2>/dev/null | head
echo
echo "=== usb device table? ==="
grep -rn 'USB_DEVICE(0x' "$D/os_dep/linux/usb_intf.c" | head -10
