#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/joypad/drv

echo "=== config sanity ==="
grep '^CONFIG_LOCALVERSION=' "$K/.config"

cd "$K"
make ARCH=arm64 CROSS_COMPILE="$TC" olddefconfig >/dev/null
make ARCH=arm64 CROSS_COMPILE="$TC" -j"$(nproc)" modules_prepare >/dev/null 2>&1 || true
grep -E '^CONFIG_MODULES=' include/config/auto.conf

cd "$D"
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" KBUILD_MODPOST_WARN=1 modules > /tmp/joy.log 2>&1 || true
echo "=== errors ==="
grep -n ' error:' /tmp/joy.log | head -20
echo "=== warnings (first 10) ==="
grep -n 'warning:' /tmp/joy.log | head -10
echo "=== tail ==="
tail -8 /tmp/joy.log
echo "=== result ==="
ls -l *.ko 2>/dev/null || echo NO_KO
for f in *.ko; do
  [ -f "$f" ] || continue
  python3 -c "
d=open('$f','rb').read()
i=d.find(b'vermagic=')
print('$f', d[i:i+120].split(b'\x00')[0].decode())
"
done
