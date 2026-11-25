#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/rtl8733bu/drv
cd "$D"
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" \
     CONFIG_RTL8733BU=m KBUILD_MODPOST_WARN=1 V=1 os_dep/linux/os_intfs.o > /tmp/wifi.log 2>&1
echo "exit=$?"
echo "=== gcc cmdline Werror bits ==="
grep -o '\-W[a-z=-]*error[a-z=-]*' /tmp/wifi.log | sort -u | head
echo "=== first errors ==="
grep -n 'error' /tmp/wifi.log | head -10
echo "=== env ==="
echo "KBUILD_EXTRA_WARN=${KBUILD_EXTRA_WARN:-<unset>}"
