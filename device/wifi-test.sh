#!/bin/sh
IF=$(ip -o link | awk -F': ' '{print $2}' | grep '^wl' | head -1)
echo "wifi iface: $IF"
echo
echo "=== nmcli device ==="
nmcli device status 2>&1 | head -10
echo
echo "=== scan (10s) ==="
nmcli --wait 15 device wifi list ifname "$IF" 2>&1 | head -15
echo
echo "=== iw dev info ==="
iw dev 2>/dev/null | head -12 || echo "  iw not installed"
echo
echo "=== rfkill ==="
rfkill list 2>&1 | head -8
