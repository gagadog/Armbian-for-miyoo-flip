#!/bin/bash
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -fP --show "$IMG")
mount "${L}p2" "$R"
echo "=== display manager wiring ==="
ls -l "$R/etc/systemd/system/display-manager.service" 2>/dev/null || echo "  NO display-manager.service symlink!"
ls -l "$R/etc/systemd/system/default.target" 2>/dev/null
echo
echo "=== gadget service ==="
sed -n '1,20p' "$R/etc/systemd/system/miyoo-usb-gadget.service"
echo
echo "=== iproute2 present? ==="
ls -l "$R/usr/sbin/ip" "$R/sbin/ip" 2>/dev/null | head -2
echo
echo "=== dnsmasq drop-in ==="
cat "$R/etc/systemd/system/dnsmasq.service.d/10-usb0.conf"
echo
echo "=== antimicrox wrapper ==="
sed -n '1,12p' "$R/home/miyoo/.local/bin/antimicrox-logged"
sync; umount "$R"; losetup -d "$L"

echo
echo "=== xz integrity ==="
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
xz -t Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v3.img.xz && echo "xz OK"
ls -l
