#!/bin/bash
set -e
cd "$HOME/miyoo-build"
mkdir -p img src
echo "--- kernel 7.3.5 ---"
cd src
[ -f linux-7.3.5.tar.xz ] || curl -sL --retry 5 --retry-all-errors -O https://mirrors.tuna.tsinghua.edu.cn/kernel/v7.x/linux-7.3.5.tar.xz
ls -l linux-7.3.5.tar.xz
echo "--- armbian image ---"
cd ../img
URL="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/anbernic-rg-ds/archive/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img.xz"
[ -f "$(basename "$URL")" ] || curl -sL --retry 5 --retry-all-errors -O "$URL"
ls -l
echo DONE
