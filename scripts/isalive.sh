#!/bin/bash
OUT=/mnt/c/Users/wang/.local/share/opencode/shell/2d874241e5d32358b35f74243c57a13eb5857d0b/sh_2123f8b86001EyEpt8Gm4dog6P.out
echo "=== log mtime / size ==="
ls -l "$OUT"
date
echo
echo "=== last 15 lines ==="
tail -15 "$OUT"
echo
echo "=== stage1b / apt / qemu processes ==="
ps -eo pid,etime,pcpu,stat,comm,args --sort=-pcpu | grep -Ei 'desktop1b|apt-get|dpkg|qemu|chroot' | grep -v grep | head -20
echo
echo "=== load ==="
uptime
echo
echo "=== chroot filesystem activity: newest files ==="
find /mnt/miyoo-root/var/lib/dpkg -newermt '-3 minutes' 2>/dev/null | head -5
echo
echo "=== dpkg lock holders ==="
ls -l /mnt/miyoo-root/var/lib/dpkg/lock-frontend 2>/dev/null
fuser -v /mnt/miyoo-root/var/lib/dpkg/lock-frontend 2>&1 | head -5
echo
echo "=== apt archive cache growing? ==="
du -sh /mnt/miyoo-root/var/cache/apt/archives 2>/dev/null
ls -lt /mnt/miyoo-root/var/cache/apt/archives/*.deb 2>/dev/null | head -3
