#!/bin/bash
# Verify that panel-generic-dsi.c compiles for aarch64 against a mainline tree.
set -e
K="$HOME/miyoo-build/src/linux-6.12.119"
TC="$HOME/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
M="/mnt/d/wendang/默认项目/miyoo-flip-dtb/module"

cd "$K"
echo "=== defconfig + modules_prepare ==="
make ARCH=arm64 CROSS_COMPILE="$TC" defconfig >/dev/null
make ARCH=arm64 CROSS_COMPILE="$TC" -j"$(nproc)" modules_prepare >/dev/null
echo "=== build module ==="
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$M" modules 2>&1 | tail -25
echo "=== result ==="
ls -l "$M"/panel-generic-dsi.ko 2>/dev/null || echo "NO .ko"
file "$M"/panel-generic-dsi.ko 2>/dev/null || true
