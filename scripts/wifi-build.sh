#!/bin/bash
set -e
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/rtl8733bu/drv
cd "$D"
grep -n 'CONFIG_CONCURRENT_MODE' Makefile | head
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" \
     CONFIG_RTL8733BU=m KBUILD_MODPOST_WARN=1 modules 2>&1 | tail -25
echo "=== result ==="
ls -l "$D"/8733bu.ko 2>/dev/null || { echo NO_KO; exit 1; }
python3 -c "
d=open('$D/8733bu.ko','rb').read()
i=d.find(b'vermagic=')
print(d[i:i+120].split(b'\x00')[0].decode())
"
