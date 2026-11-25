#!/bin/bash
set -e
SYS=/mnt/bfos1/SYSTEM
D=/home/wang/miyoo-build/firmware/extract
mkdir -p "$D"
cd "$D"

echo "=== extract modprobe/modules-load configs ==="
unsquashfs -q -f -d "$D/root" "$SYS" \
    'squashfs-root/usr/lib/modprobe.d/*' \
    'squashfs-root/usr/lib/modules-load.d/*' >/dev/null 2>&1 || true

for f in root/usr/lib/modprobe.d/8733bu.conf root/usr/lib/modprobe.d/rtl8733bu-combo.conf root/usr/lib/modules-load.d/rtl8733bu-power.conf; do
    echo "----- $f -----"
    cat "$f" 2>/dev/null | grep -vE '^\s*#' | grep -v '^$' | head -20
done

echo
echo "=== any firmware file mentioning 8733 in the whole SYSTEM? ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -iE 'firmware/.*(8733|rtl8733)' | head -20 || echo "  none"

echo
echo "=== does their 8733bu.ko reference firmware paths? ==="
unsquashfs -q -f -d "$D/ko" "$SYS" \
    'squashfs-root/usr/lib/kernel-overlays/base/lib/modules/7.0.2/kernel/drivers/net/wireless/8733bu.ko' >/dev/null 2>&1 || true
ls -l ko/usr/lib/kernel-overlays/base/lib/modules/7.0.2/kernel/drivers/net/wireless/8733bu.ko 2>/dev/null
strings ko/usr/lib/kernel-overlays/base/lib/modules/7.0.2/kernel/drivers/net/wireless/8733bu.ko 2>/dev/null \
    | grep -iE '\.bin|\.txt|/lib/firmware|rtlwifi' | sort -u | head -20
