#!/bin/bash
# Cross-build panel-generic-dsi.ko against a prepared kernel source tree.
#
#   ./build-module.sh [/path/to/linux-6.12.x] [aarch64-none-linux-gnu-]
#
# The kernel tree must already have a .config and generated headers:
#   make ARCH=arm64 <your defconfig>
#   make ARCH=arm64 modules_prepare
#
# Note: without the target kernel's Module.symvers the resulting .ko will have
# the right architecture but may fail to load (unknown symbol / vermagic
# mismatch). For a real device, build on the device or inside its rootfs.
set -e
KDIR="${1:-$HOME/miyoo-build/src/linux-6.12.119}"
CROSS="${2:-aarch64-none-linux-gnu-}"
HERE="$(cd "$(dirname "$0")" && pwd)"

make -C "$KDIR" ARCH=arm64 CROSS_COMPILE="$CROSS" M="$HERE" modules
ls -l "$HERE"/panel-generic-dsi.ko
