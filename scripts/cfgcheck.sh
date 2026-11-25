#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in CONFIGFS_FS USB_GADGET USB_LIBCOMPOSITE USB_CONFIGFS USB_CONFIGFS_RNDIS \
         USB_F_RNDIS USB_GADGET_DWC3 USB_DWC3 USB_DWC3_DUAL_ROLE USB_DWC3_OTG \
         USB_GADGET_STORAGE_NUM_BUFFERS USB_ROLE_SWITCH; do
  line=$(grep -E "^${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-32s %s\n' "$k" "$line"
done
echo
echo "=== configfs mount unit shipped? ==="
ls /usr/lib/systemd/system/sys-kernel-config.mount 2>/dev/null || echo "  (checking image instead)"
