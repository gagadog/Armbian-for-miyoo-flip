#!/bin/bash
# Re-mount the finished image, verify the desktop + USB changes, then repack.
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce.img.xz"

sync
umount /mnt/miyoo-boot 2>/dev/null || true
umount /mnt/miyoo-root 2>/dev/null || true
for l in $(losetup -j "$IMG" | cut -d: -f1); do losetup -d "$l"; done
sleep 1

LOOP=$(losetup -fP --show "$IMG")
mount "${LOOP}p1" /mnt/miyoo-boot
mount "${LOOP}p2" /mnt/miyoo-root

echo "================ VERIFY ================"
echo "--- boot env ---"
grep -E 'fdtfile|extraargs' /mnt/miyoo-boot/armbianEnv.txt
echo "--- dtb ---"
ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb
echo "--- dtb usb nodes ---"
dtc -I dtb -O dts /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb -o /tmp/v.dts 2>/dev/null
for n in 'usb@fcc00000' 'usb@fd000000' 'usb@fd800000' 'usb@fd840000' 'usb@fd880000' 'usb@fd8c0000'; do
    st=$(awk -v pat="$n" 'index($0,pat) && /\{/ {f=1} f {print} f && /^\t\};/ {f=0}' /tmp/v.dts | grep -m1 'status')
    echo "  $n -> $st"
done
awk '/usb@fcc00000 \{/{f=1} f{print} f&&/^\t\};/{exit}' /tmp/v.dts | grep -E 'dr_mode'
echo "--- panel module ---"
ls -l /mnt/miyoo-root/lib/modules/7.3.5-edge-rockchip64/extra/
echo "--- desktop ---"
ls /mnt/miyoo-root/usr/share/xsessions/
for b in usr/bin/startxfce4 usr/sbin/lightdm usr/bin/antimicrox usr/bin/onboard; do
    printf '  %-24s %s\n' "$b" "$(ls /mnt/miyoo-root/$b 2>/dev/null || echo MISSING)"
done
echo "--- user + autologin ---"
grep '^miyoo:' /mnt/miyoo-root/etc/passwd
cat /mnt/miyoo-root/etc/lightdm/lightdm.conf.d/60-miyoo-autologin.conf
echo "--- antimicrox profile ---"
ls -l /mnt/miyoo-root/home/miyoo/.config/antimicrox/profiles/
cat /mnt/miyoo-root/etc/modules-load.d/uinput.conf
echo "--- disk usage ---"
df -h /mnt/miyoo-root

sync
umount /mnt/miyoo-boot
umount /mnt/miyoo-root
losetup -d "$LOOP"
echo "================ PACK ================"
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
echo PACK_DONE
