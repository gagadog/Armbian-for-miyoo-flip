#!/bin/bash
# Prebuild out-of-tree modules against the exact kernel config shipped in the
# Armbian image (7.3.5-edge-rockchip64).
#
# CONFIG_MODVERSIONS is off in that kernel, so only vermagic must match.
# We therefore set CONFIG_LOCALVERSION="-edge-rockchip64" to reproduce the
# release string exactly.
set -e
V=7.3.5
K="/home/wang/miyoo-build/src/linux-$V"
TC="/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
CFG=/mnt/miyoo-boot/config-7.3.5-edge-rockchip64

cd "$K"
cp "$CFG" .config
./scripts/config --file .config --set-str LOCALVERSION "-edge-rockchip64"
make ARCH=arm64 CROSS_COMPILE="$TC" olddefconfig >/dev/null
echo "=== release ==="
make -s ARCH=arm64 CROSS_COMPILE="$TC" kernelrelease
echo "=== modules_prepare ==="
make ARCH=arm64 CROSS_COMPILE="$TC" -j"$(nproc)" modules_prepare 2>&1 | tail -5

echo "=== panel module ==="
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" \
     M="/mnt/d/wendang/默认项目/miyoo-flip-dtb/module" KBUILD_MODPOST_WARN=1 modules 2>&1 | tail -15
ls -l "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.ko" || true
