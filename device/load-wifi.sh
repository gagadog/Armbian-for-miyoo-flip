#!/bin/sh
REL=7.3.5-edge-rockchip64
set -e

echo "=== install module ==="
install -D -m 644 /tmp/8733bu.ko \
    /lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko
depmod -a $REL
modinfo -F vermagic /lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko

echo
echo "=== install ROCKNIX modprobe config ==="
install -D -m 644 /tmp/8733bu.conf /etc/modprobe.d/8733bu.conf
install -D -m 644 /tmp/rtl8733bu-combo.conf /etc/modprobe.d/rtl8733bu-combo.conf
grep -E '^(options|blacklist|softdep)' /etc/modprobe.d/8733bu.conf /etc/modprobe.d/rtl8733bu-combo.conf 2>/dev/null | head

echo
echo "=== load ==="
modprobe 8733bu 2>&1 || true
sleep 4
lsmod | grep -E '8733|cfg80211' || echo "  not loaded"

echo
echo "=== dmesg ==="
dmesg 2>/dev/null | grep -iE '8733|rtw|firmware|wlan' | tail -25

echo
echo "=== interfaces ==="
ip -o link | cut -d: -f2
echo
echo "=== rfkill ==="
rfkill list 2>/dev/null | head -10
