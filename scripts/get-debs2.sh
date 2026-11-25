#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs
for p in gir1.2-atspi-2.0 libatk-adaptor gir1.2-atk-1.0; do
    ver=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Version:" {print $2; exit}' Packages)
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    [ -z "$fn" ] && { echo "  $p NOT FOUND"; continue; }
    base=$(basename "$fn")
    echo "  $p $ver -> $base"
    [ -f "$base" ] || curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn"
done
echo
ls -l *.deb | awk '{print "  "$5" "$9}'
