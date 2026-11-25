#!/bin/bash
# Determine antimicrox's Qt version and whether the xcb plugin's dependencies
# are actually present in the image (host has binutils, so no chroot needed).
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mount "${L}p2" "$R"

echo "=== antimicrox NEEDED libs ==="
objdump -p "$R/usr/bin/antimicrox" 2>/dev/null | grep NEEDED | sed 's/.*NEEDED *//' | sort | head -30

echo
echo "=== Qt platform plugin dirs ==="
ls -d "$R"/usr/lib/aarch64-linux-gnu/qt*/plugins/platforms 2>/dev/null
ls -l "$R"/usr/lib/aarch64-linux-gnu/qt*/plugins/platforms/libqxcb.so 2>/dev/null

echo
echo "=== libqxcb.so NEEDED ==="
QX=$(ls "$R"/usr/lib/aarch64-linux-gnu/qt*/plugins/platforms/libqxcb.so 2>/dev/null | head -1)
objdump -p "$QX" 2>/dev/null | grep NEEDED | sed 's/.*NEEDED *//' | sort

echo
echo "=== presence check of every NEEDED lib of libqxcb ==="
for lib in $(objdump -p "$QX" 2>/dev/null | grep NEEDED | sed 's/.*NEEDED *//'); do
  if [ -e "$R/usr/lib/aarch64-linux-gnu/$lib" ] || ls "$R"/usr/lib/aarch64-linux-gnu/*/"$lib" >/dev/null 2>&1; then
    :
  else
    echo "  MISSING: $lib"
  fi
done
echo "(no output above the line = all present)"

echo
echo "=== dpkg: antimicrox deps ==="
awk '/^Package: antimicrox$/,/^$/' "$R/var/lib/dpkg/status" | grep -E '^(Version|Depends|Recommends)'

echo
echo "=== xcb-util / cursor packages installed? ==="
for p in libxcb-cursor0 libxkbcommon-x11-0 libqt6svg6 libqt6wlshellintegration6; do
  if grep -q "^Package: $p$" "$R/var/lib/dpkg/status"; then echo "  OK      $p"; else echo "  MISSING $p"; fi
done

sync; umount "$R"; losetup -d "$L"
