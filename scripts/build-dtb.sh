#!/bin/bash
# Build the Armbian-portable Miyoo Flip DTB against several mainline trees.
set -e
SRC="/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts"
for K in "$HOME/miyoo-build/src/linux-6.12.119" "$HOME/miyoo-build/src/linux-6.6.163"; do
	echo "=================== $K ==================="
	cp "$SRC" "$K/arch/arm64/boot/dts/rockchip/"
	( cd "$K" && make ARCH=arm64 allnoconfig >/dev/null && make ARCH=arm64 -j"$(nproc)" rockchip/rk3566-miyoo-flip-armbian.dtb ) || exit 1
	ls -l "$K/arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-armbian.dtb"
done
