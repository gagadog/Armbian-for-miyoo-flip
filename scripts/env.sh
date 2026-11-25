#!/bin/bash
# 所有构建脚本共用的路径定义。换机器时只需要改这一处（或用环境变量覆盖）：
#
#   BUILD=~/work ROOT=/path/to/repo ./scripts/fold-v7.sh
#
# ROOT  = 本仓库根目录（scripts/ 的上一级）
# BUILD = 构建工作区：内核源码、Armbian 底包、离线 deb、摇杆/网卡驱动源码

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUILD="${BUILD:-$HOME/miyoo-build}"

K="$BUILD/src/linux-7.3.5"                                              # 内核源码树
TC="$BUILD/toolchain/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-"
IMG="$BUILD/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img"
DEBS="$BUILD/debs"                                                      # 离线 arm64 deb
JOYPAD="$BUILD/joypad/drv"                                              # 摇杆驱动源码
WIFI="$BUILD/rtl8733bu/tip"                                             # RTL8733BU 驱动源码

export ROOT BUILD K TC IMG DEBS JOYPAD WIFI
