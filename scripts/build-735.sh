#!/bin/bash
# Build the Armbian-portable Miyoo Flip DTB against the exact kernel the
# Armbian image ships (7.3.5).
set -e
V="${1:-7.3.5}"
SRC="/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts"
K="$HOME/miyoo-build/src/linux-$V"

cd "$HOME/miyoo-build/src"
[ -d "linux-$V" ] || tar -xf "linux-$V.tar.xz"
cd "$K"

# Preserve the kernel config (needed later for out-of-tree module builds);
# the DTB-only build below runs allnoconfig, which would clobber it.
[ -f .config ] && cp .config /tmp/kconfig.keep

cp "$SRC" arch/arm64/boot/dts/rockchip/
make ARCH=arm64 allnoconfig >/dev/null
make ARCH=arm64 -j"$(nproc)" rockchip/rk3566-miyoo-flip-armbian.dtb 2>&1 | tail -25

[ -f /tmp/kconfig.keep ] && cp /tmp/kconfig.keep .config

ls -l arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-armbian.dtb
