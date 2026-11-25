#!/bin/bash
D=/home/wang/miyoo-build/rtl8733bu/tip
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== numbered 10960-10990 ==="
awk 'NR>=10960 && NR<=10990 {printf "%d: %s\n", NR, $0}' "$D/os_dep/linux/ioctl_cfg80211.c"
echo
echo "=== kernel: set_bitrate_mask decl ==="
grep -rn 'set_bitrate_mask' "$K/include/net/cfg80211.h" | head
echo "=== kernel: mgmt_tx decl ==="
grep -rn '\*mgmt_tx' "$K/include/net/cfg80211.h" | head
