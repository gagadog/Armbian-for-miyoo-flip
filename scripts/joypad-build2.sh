#!/bin/bash
# Build rocknix-singleadc-joypad against the Armbian 7.3.5 tree, using a shim for
# the input-polldev API that mainline removed in 6.14.
set -e
set -o pipefail
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/joypad/drv
S="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"

cp -f "$S/compat-input-polldev.h" "$D/compat-input-polldev.h"

cd "$D"
sed -i 's|#include <linux/input-polldev.h>|#include "compat-input-polldev.h"|' rocknix-singleadc-joypad.c
grep -n 'compat-input-polldev' rocknix-singleadc-joypad.c

# only the single-ADC variant is needed on RK3566
printf 'obj-m := rocknix-singleadc-joypad.o\n' > Makefile
cat Makefile

echo "=== build ==="
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" KBUILD_MODPOST_WARN=1 modules \
    > /tmp/joy2.log 2>&1 || true
echo "=== errors ==="
grep -n ' error:' /tmp/joy2.log | head -20
echo "=== warnings ==="
grep -n 'warning:' /tmp/joy2.log | head -12
echo "=== tail ==="
tail -6 /tmp/joy2.log
echo "=== result ==="
if [ -f rocknix-singleadc-joypad.ko ]; then
    ls -l rocknix-singleadc-joypad.ko
    python3 -c "
d=open('rocknix-singleadc-joypad.ko','rb').read()
i=d.find(b'vermagic=')
print('vermagic:', d[i:i+120].split(b'\x00')[0].decode())
"
else
    echo NO_KO
fi
