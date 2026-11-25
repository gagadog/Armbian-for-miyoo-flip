#!/bin/bash
# Fix the two link/namespace problems that stop rocknix-singleadc-joypad from
# loading on a vanilla 7.3 kernel:
#   1. joypad_input_g is declared extern but never defined (upstream builds it
#      together with rocknix-joypad.c, which we do not ship)
#   2. IIO consumer symbols live in the IIO_CONSUMER namespace, so the module
#      must import it or the kernel rejects the load with -EINVAL
set -e
set -o pipefail
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/joypad/drv
S="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"

cp -f "$S/compat-input-polldev.h" "$D/compat-input-polldev.h"
cd "$D"

# 1. give joypad_input_g a real definition in this translation unit
if grep -q '^extern struct input_dev \* joypad_input_g;' rocknix-singleadc-joypad.c; then
    sed -i 's|^extern struct input_dev \* joypad_input_g;|/* singleadc is built standalone here, so own the symbol */\nstatic struct input_dev *joypad_input_g;|' rocknix-singleadc-joypad.c
    echo "joypad_input_g: made static"
fi
grep -n 'joypad_input_g' rocknix-singleadc-joypad.c

# 2. import the IIO consumer namespace
if ! grep -q 'MODULE_IMPORT_NS' rocknix-singleadc-joypad.c; then
    sed -i 's|^MODULE_LICENSE("GPL");|MODULE_IMPORT_NS("IIO_CONSUMER");\nMODULE_LICENSE("GPL");|' rocknix-singleadc-joypad.c
    echo "MODULE_IMPORT_NS added"
fi
grep -n 'MODULE_IMPORT_NS\|MODULE_LICENSE' rocknix-singleadc-joypad.c

printf 'obj-m := rocknix-singleadc-joypad.o\n' > Makefile

echo "=== refresh kernel config (DTB builds leave auto.conf on allnoconfig) ==="
cd "$K"
make ARCH=arm64 CROSS_COMPILE="$TC" olddefconfig >/dev/null
make ARCH=arm64 CROSS_COMPILE="$TC" -j"$(nproc)" modules_prepare >/dev/null 2>&1 || true
grep -E '^CONFIG_MODULES=' include/config/auto.conf
cd "$D"

echo "=== build ==="
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" KBUILD_MODPOST_WARN=1 modules \
    > /tmp/joy3.log 2>&1 || true
grep -n ' error:' /tmp/joy3.log | head -20 || true
tail -4 /tmp/joy3.log
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
