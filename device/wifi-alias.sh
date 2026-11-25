#!/bin/sh
REL=7.3.5-edge-rockchip64
echo "=== usb alias for the module ==="
grep -i 'v0BDA' /lib/modules/$REL/modules.alias | grep -i 8733 || \
  grep -i '8733' /lib/modules/$REL/modules.alias | head -5 || echo "  no alias"
echo
echo "=== module dir ==="
ls -l /lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko
echo
echo "=== modprobe.d ==="
ls -l /etc/modprobe.d/8733bu.conf /etc/modprobe.d/rtl8733bu-combo.conf
