#!/bin/bash
K="$HOME/miyoo-build/src/linux-6.12.119/arch/arm64/boot/dts/rockchip"
D="/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts"
cd "$K" || exit 1
F="rk3566.dtsi rk3566-base.dtsi rk3568.dtsi rk356x-base.dtsi rk3568-pinctrl.dtsi"
grep -ohE '[a-zA-Z0-9_]+:' $F | tr -d ':' | sort -u > /tmp/labels.txt
grep -ohE '&[a-zA-Z0-9_]+' "$D" | tr -d '&' | sort -u > /tmp/refs.txt
echo "=== referenced labels missing in mainline dtsi ==="
comm -23 /tmp/refs.txt /tmp/labels.txt
echo
echo "=== io-domain / vop / dphy labels ==="
grep -nE 'io-domains|vop_mmu:|dsi_dphy0:|hdmi_in:|video_phy' $F | head -20
