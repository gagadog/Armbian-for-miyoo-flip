#!/bin/bash
set -e
set -o pipefail
K=/home/wang/miyoo-build/src/linux-7.3.5
TC=/home/wang/miyoo-build/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
D=/home/wang/miyoo-build/joypad
PIN=1dd1115c8d231ba934253efb91ffb0c6ad8e993d
B="https://cdn.jsdelivr.net/gh/KeatenPerkins/butterflyOS@butterflyOS-main/projects/ROCKNIX/packages/linux-drivers/rocknix-joypad/patches"

mkdir -p "$D"
cd "$D"
if [ ! -f src.tar.gz ]; then
    curl -sL --retry 5 --retry-all-errors --max-time 300 -o src.tar.gz \
        "https://github.com/ROCKNIX/rocknix-joypad/archive/$PIN.tar.gz"
fi
ls -l src.tar.gz
rm -rf drv && mkdir drv && tar -xf src.tar.gz -C drv --strip-components=1
echo "=== files ==="
ls drv | head -20
echo "=== Makefile ==="
cat drv/Makefile 2>/dev/null | head -20

echo "=== fetch patches ==="
mkdir -p patches
for p in 001-singleadc-check-iio-read-errors.patch \
         0002-miyoo-serial-use-dts-deadzone-fuzz-flat-tuning.patch \
         0003-miyoo-serial-live-range-expansion-sysfs-calibration.patch; do
    [ -f "patches/$p" ] || curl -sL --retry 5 -o "patches/$p" "$B/$p"
done
ls -l patches

echo "=== apply ==="
cd drv
for p in ../patches/*.patch; do
    echo "-- $(basename "$p")"
    patch -p1 --forward < "$p" && echo "   ok" || echo "   FAILED"
done
