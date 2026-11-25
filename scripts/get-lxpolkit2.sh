#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs
for p in lxpolkit lxsession-data; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    [ -z "$fn" ] && { echo "  $p NOT FOUND"; continue; }
    base=$(basename "$fn")
    [ -f "$base" ] || curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn"
    printf '  %-40s %s bytes\n' "$base" "$(stat -c %s "$base")"
done
