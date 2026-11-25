#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in CONFIGFS_FS USB_GADGET USB_LIBCOMPOSITE USB_CONFIGFS USB_CONFIGFS_RNDIS \
         USB_F_RNDIS USB_F_ECM USB_F_ECM_SUBSET USB_GADGET_DWC3 USB_DWC3 \
         USB_DWC3_DUAL_ROLE USB_DWC3_OTG USB_ROLE_SWITCH; do
  line=$(grep -E "^CONFIG_${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-32s %s\n' "$k" "$line"
done
