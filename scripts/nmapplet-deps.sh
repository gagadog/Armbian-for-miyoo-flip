#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs

show() {
    local p="$1"
    echo "=== $p ==="
    awk -v pkg="$p" '
        $1=="Package:" && $2==pkg {f=1}
        f && /^(Version|Depends|Recommends):/ {print "  "$0}
        f && $1=="Description:" {exit}
    ' Packages | head -6
}

show network-manager-applet
show libnma0
show libnma-common
echo
echo "=== filenames ==="
for p in network-manager-applet libnma0 libnma-common; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    echo "  $p -> $(basename "${fn:-MISSING}")"
done
