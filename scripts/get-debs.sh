#!/bin/bash
# Fetch arm64 .debs for onboard's AT-SPI dependencies from the TUNA mirror.
set -e
set -o pipefail
D=/home/wang/miyoo-build/debs
mkdir -p "$D"
cd "$D"

PKGS="python3-pyatspi at-spi2-core libatspi2.0-0t64 gsettings-desktop-schemas libatk1.0-0t64"

echo "=== fetch Packages index ==="
[ -f Packages ] || curl -s --retry 3 --max-time 300 \
    "https://mirrors.tuna.tsinghua.edu.cn/debian/dists/trixie/main/binary-arm64/Packages.gz" \
    | gunzip > Packages
wc -l Packages

for p in $PKGS; do
    echo "=== $p ==="
    ver=$(awk -v pkg="$p" '
        $1=="Package:" && $2==pkg {found=1}
        found && $1=="Version:" {print $2; exit}
    ' Packages)
    fn=$(awk -v pkg="$p" '
        $1=="Package:" && $2==pkg {found=1}
        found && $1=="Filename:" {print $2; exit}
    ' Packages)
    if [ -z "$ver" ] || [ -z "$fn" ]; then
        echo "  not found in main, trying elsewhere"
        continue
    fi
    base=$(basename "$fn")
    echo "  $ver  $base"
    if [ ! -f "$base" ]; then
        curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn"
    fi
    ls -l "$base" | awk '{print "  "$5" bytes"}'
done

echo
echo "=== files ==="
ls -l *.deb 2>/dev/null | awk '{print "  "$5" "$9}'
