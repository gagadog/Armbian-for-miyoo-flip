#!/bin/bash
set -e
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
mkdir -p "$O/wifi"
cp "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.ko" \
   "$O/panel-generic-dsi-7.3.5-edge-rockchip64.ko"
cp /home/wang/miyoo-build/rtl8733bu/tip/8733bu.ko \
   "$O/wifi/8733bu-7.3.5-edge-rockchip64.ko"
ls -l "$O" "$O/wifi"
