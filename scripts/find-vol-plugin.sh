#!/bin/bash
cd /home/wang/miyoo-build/debs
for p in volumeicon-alsa pnmixer volumebar xfce4-mixer; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    if [ -z "$fn" ]; then
        echo "  $p -> NOT IN trixie"
    else
        dep=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && /^Depends:/ {print $0; exit}' Packages)
        echo "  $p -> $(basename "$fn")"
        echo "     $dep"
    fi
done
