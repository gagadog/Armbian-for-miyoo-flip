#!/bin/bash
OUT=/mnt/c/Users/wang/.local/share/opencode/shell/2d874241e5d32358b35f74243c57a13eb5857d0b/sh_212589cb2001G7TebSipNyEoJq.out
echo "=== now ==="; date
echo "=== log ==="; ls -l "$OUT"; tail -30 "$OUT"
echo
echo "=== procs ==="
ps -eo pid,etime,pcpu,comm,args --sort=-pcpu | grep -Ei 'desktop2|apt-get|dpkg|qemu' | grep -v grep | head -8
