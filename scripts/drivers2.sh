#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in KEYBOARD_GPIO_POLLED INPUT_EVDEV BACKLIGHT_PWM PWM_ROCKCHIP SND_SIMPLE_CARD SND_SOC_RK817 \
         MFD_RK8XX_I2C RTC_DRV_RK808 CHARGER_RK817 BATTERY_RK817 REGULATOR_RK808 \
         DRM_DW_MIPI_DSI MMC_DW_ROCKCHIP MTD_SPI_NAND CFG80211 MAC80211 \
         PHY_ROCKCHIP_INNO_DSIDPHY; do
  line=$(grep -E "^CONFIG_${k}=" "$C")
  if [ -z "$line" ]; then
      line="--- MISSING/# not set ---"
  fi
  printf '%-32s %s\n' "$k" "$line"
done
