#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in SND_SOC_ROCKCHIP_I2S_TDM SND_SOC_ROCKCHIP_I2S SND_SIMPLE_CARD_UTILS SND_SOC_ROCKCHIP_MULTICODECS \
         SND_SOC_ROCKCHIP_SPDIF PWM_BL_PWM_V4 REGULATOR_FIXED_VOLTAGE SIMPLE_PM_BUS; do
  line=$(grep -E "^CONFIG_${k}=" "$C")
  [ -z "$line" ] && line="--- MISSING/# not set ---"
  printf '%-36s %s\n' "$k" "$line"
done
echo
echo "=== DTS audio nodes ==="
grep -n 'i2s1_8ch\|rk817_codec\|sound {' -A3 "/mnt/d/wendang/默认项目/miyoo-flip-dtb/src/rk3566-miyoo-flip-armbian.dts" | head -30
