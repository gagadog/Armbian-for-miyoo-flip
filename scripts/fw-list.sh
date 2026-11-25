#!/bin/bash
set -e
SYS=/mnt/bfos1/SYSTEM
echo "=== files matching 8733 ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -i '8733' | head -40
echo
echo "=== rtlwifi firmware dir listing ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -iE 'firmware/rtlwifi' | head -30
echo
echo "=== anything named FW_NIC / AGC_TAB / PHY_REG / Radio? ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -iE 'FW_NIC|AGC_TAB|PHY_REG|Radio[ABCD]\.txt|TXPWR_LMT|TxPowerTrack|wifi_efuse|MAC_REG' | head -40
echo
echo "=== lib/firmware dirs (first 40) ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -E '^squashfs-root/usr/lib/firmware/[^/]+/$' | head -40
