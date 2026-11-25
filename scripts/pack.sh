#!/bin/bash
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
mkdir -p "$DST"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_minimal.img.xz"
cd "$DST"
xz -T0 -6 -c "$IMG" > "$NAME.part"
mv "$NAME.part" "$NAME"
ls -l "$NAME"
sha256sum "$NAME" | tee "$NAME.sha256"
echo DONE
