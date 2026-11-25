#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in INPUT_UINPUT INPUT_EVDEV INPUT_JOYDEV DRM_FBDEV_EMULATION DRM_ROCKCHIP \
         DRM_TINYDRM FB_SIMPLE VT_CONSOLE FRAMEBUFFER_CONSOLE INPUT_MOUSEDEV \
         USB_HID HID_GENERIC INPUT_KEYBOARD; do
  line=$(grep -E "^CONFIG_${k}=" "$C")
  [ -z "$line" ] && line="--- not set ---"
  printf '%-26s %s\n' "$k" "$line"
done
