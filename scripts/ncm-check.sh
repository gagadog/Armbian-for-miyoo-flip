#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in USB_CONFIGFS_NCM USB_F_NCM USB_CONFIGFS_ECM USB_F_ECM USB_CONFIGFS_EEM USB_F_EEM; do
  line=$(grep -E "^CONFIG_${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-26s %s\n' "$k" "$line"
done
