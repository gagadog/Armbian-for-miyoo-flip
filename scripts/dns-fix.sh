#!/bin/bash
R=/mnt/miyoo-root
echo "=== host resolv.conf ==="
cat /etc/resolv.conf
ls -l /etc/resolv.conf
echo
echo "=== rootfs resolv.conf ==="
ls -l "$R/etc/resolv.conf"
cat "$R/etc/resolv.conf" 2>/dev/null
echo
echo "=== nsswitch hosts ==="
grep '^hosts' "$R/etc/nsswitch.conf"
echo
echo "=== chroot getent ==="
mountpoint -q "$R/proc" || mount --bind /proc "$R/proc"
mountpoint -q "$R/dev" || mount --bind /dev "$R/dev"
chroot "$R" /usr/bin/env LANG=C getent hosts mirrors.tuna.tsinghua.edu.cn 2>&1 | head -3
echo "rc=$?"
echo
echo "=== fix: replace with regular file + bind mount host resolv.conf ==="
if [ -L "$R/etc/resolv.conf" ]; then
    rm -f "$R/etc/resolv.conf"
    touch "$R/etc/resolv.conf"
fi
mountpoint -q "$R/etc/resolv.conf" || mount --bind /etc/resolv.conf "$R/etc/resolv.conf"
cat "$R/etc/resolv.conf"
echo
echo "=== retry getent ==="
chroot "$R" /usr/bin/env LANG=C getent hosts mirrors.tuna.tsinghua.edu.cn 2>&1 | head -3
echo "rc=$?"
