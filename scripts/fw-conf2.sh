#!/bin/bash
set -e
SYS=/mnt/bfos1/SYSTEM
D=/home/wang/miyoo-build/firmware/extract
rm -rf "$D"; mkdir -p "$D"

echo "=== modprobe.d / modules-load.d ==="
unsquashfs -q -f -d "$D/cfg" "$SYS" usr/lib/modprobe.d usr/lib/modules-load.d >/dev/null 2>&1 || true
find "$D/cfg" -type f 2>/dev/null | head -20
for f in $(find "$D/cfg" -type f -name '*8733*' 2>/dev/null); do
    echo "----- $f -----"
    grep -vE '^\s*$' "$f" | head -25
done

echo
echo "=== 8733bu.ko strings ==="
unsquashfs -q -f -d "$D/ko" "$SYS" \
  usr/lib/kernel-overlays/base/lib/modules/7.0.2/kernel/drivers/net/wireless/8733bu.ko >/dev/null 2>&1 || true
KO=$(find "$D/ko" -name '8733bu.ko' | head -1)
echo "ko: $KO ($(stat -c %s "$KO" 2>/dev/null) bytes)"
if [ -n "$KO" ]; then
    strings "$KO" | grep -iE '\.bin|\.txt|/lib/firmware|rtlwifi|FW_NIC|AGC_TAB|PHY_REG|Radio' | sort -u | head -25
    echo "--- vermagic ---"
    python3 -c "
d=open('$KO','rb').read(); i=d.find(b'vermagic=')
print(d[i:i+120].split(b'\x00')[0].decode())
"
fi

echo
echo "=== does SYSTEM contain any /lib/firmware at all? ==="
unsquashfs -l "$SYS" 2>/dev/null | grep -c 'lib/firmware'
