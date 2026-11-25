#!/bin/bash
D=/home/wang/miyoo-build/rtl8733bu/tip
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== 10495-10505 ==="
sed -n '10495,10505p' "$D/os_dep/linux/ioctl_cfg80211.c"
echo "=== 10955-10985 ==="
sed -n '10955,10985p' "$D/os_dep/linux/ioctl_cfg80211.c"
echo
echo "=== kernel ops: set_bitrate_mask / mgmt_tx ==="
grep -n -B2 -A6 'int (\*set_bitrate_mask)\|int (\*mgmt_tx)' "$K/include/net/cfg80211.h" | head -40
