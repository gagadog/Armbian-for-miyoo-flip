#!/bin/bash
# v6 = v5 + WiFi (8733bu) + AT-SPI (onboard) + onboard/antimicrox autostart.
set -e
set -o pipefail

IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v6.img.xz"
DEV="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
KO_WIFI=/home/wang/miyoo-build/rtl8733bu/tip/8733bu.ko
DEBS=/home/wang/miyoo-build/debs
RELCFG=/home/wang/miyoo-build/firmware/extract/cfg/usr/lib/modprobe.d
REL=7.3.5-edge-rockchip64

R=/mnt/miyoo-root
B=/mnt/miyoo-boot

echo "=== mount ==="
mountpoint -q "$R" && umount "$R" || true
mountpoint -q "$B" && umount "$B" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p1" "$B"
mount "${L}p2" "$R"

echo "=== 1. WiFi module ==="
install -D -m 644 "$KO_WIFI" "$R/lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko"
install -m 644 "$RELCFG/8733bu.conf" "$R/etc/modprobe.d/8733bu.conf"
install -m 644 "$RELCFG/rtl8733bu-combo.conf" "$R/etc/modprobe.d/rtl8733bu-combo.conf"
ls -l "$R/lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko"

echo "=== 2. AT-SPI debs (onboard needs them) ==="
install -m 755 /usr/bin/qemu-aarch64-static "$R/usr/bin/qemu-aarch64-static"
mkdir -p "$R/tmp/debs"
cp "$DEBS"/*.deb "$R/tmp/debs/"
for d in proc sys dev dev/pts; do mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"; done
cat > "$R/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "$R/usr/sbin/policy-rc.d"
chroot "$R" /bin/sh -c 'dpkg -i /tmp/debs/*.deb' 2>&1 | grep -E 'Setting up|error|depends' | head -15
chroot "$R" /usr/bin/python3 -c "import pyatspi; print('  pyatspi ok')" 2>&1 | tail -2
rm -rf "$R/tmp/debs"
rm -f "$R/usr/sbin/policy-rc.d" "$R/usr/bin/qemu-aarch64-static"
for d in dev/pts dev sys proc; do umount "$R/$d" 2>/dev/null || true; done

echo "=== 3. onboard + antimicrox autostart ==="
cat > "$R/home/miyoo/.config/autostart/onboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard -s 640x220 -x 0 -y 250
Icon=onboard
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
cat > "$R/home/miyoo/.config/autostart/antimicrox.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=AntiMicroX
Comment=Gamepad mapper (miyoo-padmouse does the mouse; this is for manual remapping)
Exec=/home/miyoo/.local/bin/antimicrox-logged
Icon=antimicrox
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
cat > "$R/home/miyoo/Desktop/onboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard -s 640x220 -x 0 -y 250
Icon=onboard
Terminal=false
EOF
chmod 755 "$R/home/miyoo/Desktop/onboard.desktop"
chown -R 1000:1000 "$R/home/miyoo/.config/autostart" "$R/home/miyoo/Desktop"

echo "=== 4. depmod ==="
depmod -b "$R" "$REL" 2>&1 | head -3 || true
grep -c '8733bu' "$R/lib/modules/$REL/modules.dep" || true
grep -i 'v0BDApB733' "$R/lib/modules/$REL/modules.alias" || true

echo
echo "================ VERIFY ================"
echo "-- wifi module --"; ls -l "$R/lib/modules/$REL/kernel/drivers/net/wireless/8733bu.ko" | awk '{print "  "$5" bytes"}'
echo "-- modprobe.d --"; ls "$R/etc/modprobe.d/" | grep -E '8733' | sed 's/^/  /'
echo "-- at-spi --"; grep -c '^Package: python3-pyatspi$' "$R/var/lib/dpkg/status" || true
echo "-- autostart --"; ls "$R/home/miyoo/.config/autostart/" | sed 's/^/  /'
echo "-- services --"; ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|usb-gadget|dnsmasq|ssh' | sed 's/^/  /'
echo "-- dtb --"; grep fdtfile "$B/armbianEnv.txt"
echo "-- disk --"; df -h "$R" | tail -1

sync
umount "$B"
umount "$R"
losetup -d "$L"

echo
echo "================ PACK ================"
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
xz -t "$DST/$NAME" && echo "xz OK"
echo V6_DONE
