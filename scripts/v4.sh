#!/bin/bash
# Install both USB-role DTBs + a role switch helper, verify, repack as v4.
set -e
set -o pipefail
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v4.img.xz"
R=/mnt/miyoo-root
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mkdir -p "$R" /mnt/miyoo-boot
mountpoint -q "$R" || mount "${L}p2" "$R"
mountpoint -q /mnt/miyoo-boot || mount "${L}p1" /mnt/miyoo-boot

echo "=== install DTBs ==="
cp "$O/rk3566-miyoo-flip-armbian-7.3.dtb" /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb
cp "$O/rk3566-miyoo-flip-usbhost-7.3.dtb" /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip-usbhost.dtb
ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip*.dtb
grep -E '^fdtfile' /mnt/miyoo-boot/armbianEnv.txt

echo "=== usb role switch ==="
cat > "$R/usr/local/sbin/miyoo-usb-role" <<'EOF'
#!/bin/sh
# Switch the bottom USB-C port between device (gadget / connect to a PC) and
# host (power + accept USB devices).  Requires a reboot.
ENV=/boot/armbianEnv.txt
case "$1" in
    device) DTB=rockchip/rk3566-miyoo-flip.dtb ;;
    host)   DTB=rockchip/rk3566-miyoo-flip-usbhost.dtb ;;
    status)
        echo "fdtfile: $(grep -E '^fdtfile=' "$ENV" | cut -d= -f2)"
        echo "available: rk3566-miyoo-flip.dtb (device), rk3566-miyoo-flip-usbhost.dtb (host)"
        exit 0 ;;
    *)
        echo "usage: $0 {device|host|status}" >&2
        echo "  device - bottom USB-C acts as a gadget (RNDIS network to a PC)" >&2
        echo "  host   - bottom USB-C powers/accepts USB devices" >&2
        exit 1 ;;
esac
if grep -q '^fdtfile=' "$ENV"; then
    sed -i "s|^fdtfile=.*|fdtfile=$DTB|" "$ENV"
else
    echo "fdtfile=$DTB" >> "$ENV"
fi
echo "fdtfile is now $DTB -- reboot to apply"
EOF
chmod +x "$R/usr/local/sbin/miyoo-usb-role"
sh -n "$R/usr/local/sbin/miyoo-usb-role" && echo "  syntax ok"

echo "=== also expose it on the desktop ==="
cat > "$R/home/miyoo/Desktop/usb-role-host.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=USB port: host mode
Comment=Make the bottom USB-C port accept USB devices, then reboot
Exec=pkexec /usr/local/sbin/miyoo-usb-role host
Icon=drive-removable-media-usb
Terminal=true
EOF
chmod +x "$R/home/miyoo/Desktop/usb-role-host.desktop"
chown -R 1000:1000 "$R/home/miyoo/Desktop" "$R/home/miyoo/.config" 2>/dev/null || true

echo
echo "================ VERIFY ================"
for f in rk3566-miyoo-flip.dtb rk3566-miyoo-flip-usbhost.dtb; do
    dtc -I dtb -O dts "/mnt/miyoo-boot/dtb/rockchip/$f" -o /tmp/v.dts 2>/dev/null
    mode=$(awk '/usb@fcc00000 \{/{f=1} f&&/dr_mode/{print $3; exit}' /tmp/v.dts)
    ohci=$(awk '/usb@fd840000 \{/{f=1} f&&/status/{print $3; exit}' /tmp/v.dts)
    printf '  %-34s dr_mode=%-13s ohci(fd840000)=%s\n' "$f" "$mode" "$ohci"
done
echo "  default fdtfile: $(grep -E '^fdtfile=' /mnt/miyoo-boot/armbianEnv.txt)"
echo "  panel module:    $(ls -l "$R/lib/modules/7.3.5-edge-rockchip64/extra/panel-generic-dsi.ko" | awk '{print $5" bytes"}')"
echo "  gadget service:  $(ls "$R/etc/systemd/system/miyoo-usb-gadget.service" >/dev/null && echo present)"
echo "  ssh key:         $(wc -c < "$R/home/miyoo/.ssh/authorized_keys") bytes"
df -h "$R" | tail -1

sync
umount /mnt/miyoo-boot
umount "$R"
losetup -d "$L"

echo "================ PACK ================"
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
xz -t "$DST/$NAME" && echo "xz OK"
echo V4_DONE
