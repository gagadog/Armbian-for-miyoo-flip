#!/bin/bash
set -e
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/rtl8733bu/drv
cp "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/rtl8733bu-compat.h" "$D/compat.h"
cd "$D"
grep -q 'include $(src)/compat.h' Makefile || \
    sed -i 's|^ccflags-y += |ccflags-y += -include $(src)/compat.h |' Makefile
grep -c 'compat.h' Makefile

make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" \
     CONFIG_RTL8733BU=m KBUILD_MODPOST_WARN=1 modules > /tmp/wifi2.log 2>&1 || true
echo "=== errors ==="
grep -n ' error:' /tmp/wifi2.log | head -10
echo "=== tail ==="
tail -6 /tmp/wifi2.log
echo "=== result ==="
ls -l "$D"/8733bu.ko 2>/dev/null && python3 -c "
d=open('$D/8733bu.ko','rb').read()
i=d.find(b'vermagic=')
print(d[i:i+120].split(b'\x00')[0].decode())
" || echo NO_KO
