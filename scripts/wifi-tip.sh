#!/bin/bash
set -e
cd /home/wang/miyoo-build/rtl8733bu
URL="https://github.com/Awesome-Embedded-Learning-Studio/rtl8733bu-linux-driver/archive/refs/heads/linux-7.1-port.tar.gz"
[ -f tip.tar.gz ] || curl -sL --retry 8 --retry-all-errors --max-time 900 -o tip.tar.gz "$URL"
ls -l tip.tar.gz
rm -rf tip && mkdir tip && tar -xf tip.tar.gz -C tip --strip-components=1
ls tip | head
echo "=== has wdev wrappers? ==="
grep -rn 'wdev_ops\|forwarder' tip/os_dep/linux/ioctl_cfg80211.c | head -5 || true
