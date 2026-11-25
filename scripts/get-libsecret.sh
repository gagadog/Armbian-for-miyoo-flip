#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs
for p in libsecret-common; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    base=$(basename "$fn")
    [ -f "$base" ] || curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn"
    echo "  $base  $(stat -c %s "$base") bytes"
done
