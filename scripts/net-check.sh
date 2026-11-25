#!/bin/bash
# Can this image be reached right now?  Check sshd + network stack + USB NICs.
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mount "${L}p2" "$R"

echo "=== sshd ==="
ls -l "$R/usr/sbin/sshd" 2>/dev/null || echo "  sshd NOT installed"
ls "$R/etc/systemd/system/multi-user.target.wants/" 2>/dev/null | grep -i ssh || echo "  ssh service not enabled in multi-user.target.wants"
grep -E '^(PermitRootLogin|PasswordAuthentication|Port)' "$R/etc/ssh/sshd_config" 2>/dev/null

echo
echo "=== network stack ==="
ls "$R/etc/systemd/system/multi-user.target.wants/" 2>/dev/null | grep -iE 'network|NetworkManager|wpa'
ls "$R/etc/systemd/network/" 2>/dev/null
ls "$R/etc/NetworkManager/system-connections/" 2>/dev/null

echo
echo "=== /etc/network/interfaces ==="
cat "$R/etc/network/interfaces" 2>/dev/null || echo "  (none)"

echo
echo "=== kernel USB ethernet / gadget config ==="
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
for k in USB_USBNET USB_NET_CDCETHER USB_NET_RNDIS_HOST USB_NET_AX88179_178A \
         USB_RTL8152 USB_NET_CDC_NCM USB_GADGET USB_CONFIGFS USB_CONFIGFS_ECM \
         USB_CONFIGFS_RNDIS USB_CONFIGFS_ECM_SUBSET USB_ETH USB_F_FS USB_LIBCOMPOSITE; do
  line=$(grep -E "^CONFIG_${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-26s %s\n' "$k" "$line"
done

echo
echo "=== hostname / avahi ==="
cat "$R/etc/hostname"

sync; umount "$R"; losetup -d "$L"
