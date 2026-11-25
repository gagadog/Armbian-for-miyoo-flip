#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs
for p in xfce4-power-manager-plugins; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    dep=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && /^Depends:/ {print $0; exit}' Packages)
    if [ -z "$fn" ]; then echo "  $p NOT FOUND"; exit 1; fi
    echo "  $p"
    echo "  $dep"
    base=$(basename "$fn")
    [ -f "$base" ] || curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn"
    ls -l "$base" | awk '{print "  "$5" bytes"}'
done
