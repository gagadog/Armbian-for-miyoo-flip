#!/bin/bash
# Fold every device-side change into the image and pack v5.
set -e
set -o pipefail

IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v5.img.xz"
DEV="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
OUT="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
KO="/home/wang/miyoo-build/joypad/drv/rocknix-singleadc-joypad.ko"
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

echo "=== 1. identity ==="
echo miyoo-flip > "$R/etc/hostname"
sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tmiyoo-flip/' "$R/etc/hosts"
grep -q '^127\.0\.1\.1' "$R/etc/hosts" || echo "127.0.1.1	miyoo-flip" >> "$R/etc/hosts"
sed -i 's/^BOARD=.*/BOARD=miyoo-flip/; s/^BOARD_NAME=.*/BOARD_NAME="Miyoo Flip"/' "$R/etc/armbian-release"
[ -f "$R/etc/armbian-image-release" ] && sed -i 's/^BOARD_NAME=.*/BOARD_NAME="Miyoo Flip"/' "$R/etc/armbian-image-release" || true
grep -E '^(BOARD|BOARD_NAME)=' "$R/etc/armbian-release"

echo "=== 2. kernel modules ==="
sed -i '/^g_serial[[:space:]]*$/d' "$R/etc/modules"
echo "  /etc/modules: $(tr '\n' ' ' < "$R/etc/modules")"
cat > "$R/etc/modprobe.d/miyoo-gadget.conf" <<'EOF'
# The Armbian RG-DS image autoloads the legacy g_serial gadget, which grabs the
# single dwc3 UDC and enumerates as 0525:a4a7 (a bare serial port), blocking the
# ACM+NCM composite gadget in miyoo-usb-gadget.service.
blacklist g_serial
blacklist g_ether
blacklist g_multi
EOF
printf 'uinput\njoydev\n' > "$R/etc/modules-load.d/uinput.conf"
echo "rocknix-singleadc-joypad" > "$R/etc/modules-load.d/rocknix-joypad.conf"

echo "=== 3. USB gadget (ACM + NCM) ==="
install -m 755 "$DEV/miyoo-usb-gadget" "$R/usr/local/sbin/miyoo-usb-gadget"
install -m 644 "$DEV/miyoo-usb-gadget.service" "$R/etc/systemd/system/miyoo-usb-gadget.service"
mkdir -p "$R/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/miyoo-usb-gadget.service \
       "$R/etc/systemd/system/multi-user.target.wants/miyoo-usb-gadget.service"
mkdir -p "$R/etc/systemd/system/dnsmasq.service.d"
cat > "$R/etc/systemd/system/dnsmasq.service.d/10-usb0.conf" <<'EOF'
[Unit]
After=miyoo-usb-gadget.service
[Service]
Restart=always
RestartSec=3
EOF
mkdir -p "$R/etc/dnsmasq.d" "$R/etc/NetworkManager/conf.d"
cat > "$R/etc/dnsmasq.d/usb0.conf" <<'EOF'
interface=usb0
bind-dynamic
dhcp-range=192.168.42.10,192.168.42.50,255.255.255.0,12h
dhcp-option=3
dhcp-option=6
EOF
cat > "$R/etc/NetworkManager/conf.d/99-usb0-unmanaged.conf" <<'EOF'
[keyfile]
unmanaged-devices=interface-name:usb0
EOF

echo "=== 4. padmouse service ==="
install -m 755 "$DEV/miyoo-padmouse.py" "$R/usr/local/bin/miyoo-padmouse"
cat > "$R/etc/systemd/system/miyoo-padmouse.service" <<'EOF'
[Unit]
Description=Miyoo Flip gamepad to mouse/keyboard mapper
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/miyoo-padmouse
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/miyoo-padmouse.service \
       "$R/etc/systemd/system/multi-user.target.wants/miyoo-padmouse.service"

echo "=== 5. antimicrox: keep the app, drop its autostart ==="
rm -f "$R/home/miyoo/.config/autostart/antimicrox.desktop"
install -d -o 1000 -g 1000 "$R/home/miyoo/.config/antimicrox/profiles"
install -m 644 -o 1000 -g 1000 "$DEV/miyoo-mouse.amgp" \
        "$R/home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp"

echo "=== 6. joypad module ==="
install -D -m 644 "$KO" "$R/lib/modules/$REL/extra/rocknix-singleadc-joypad.ko"
depmod -b "$R" "$REL" 2>&1 | head -3 || true
grep -c rocknix "$R/lib/modules/$REL/modules.dep" || true

echo "=== 7. device trees ==="
install -m 644 "$OUT/rk3566-miyoo-flip-armbian-7.3.dtb" "$B/dtb/rockchip/rk3566-miyoo-flip.dtb"
install -m 644 "$OUT/rk3566-miyoo-flip-usbhost-7.3.dtb"  "$B/dtb/rockchip/rk3566-miyoo-flip-usbhost.dtb"
install -m 644 "$OUT/rk3566-miyoo-flip-joypad-7.3.dtb"   "$B/dtb/rockchip/rk3566-miyoo-flip-joypad.dtb"
sed -i 's|^fdtfile=.*|fdtfile=rockchip/rk3566-miyoo-flip-joypad.dtb|' "$B/armbianEnv.txt"
sed -i 's/ systemd.mask=miyoo-usb-gadget\.service//' "$B/armbianEnv.txt"
grep -E '^(fdtfile|extraargs)' "$B/armbianEnv.txt"

echo "=== 8. drop the RG-DS gamepad remap daemon ==="
rm -f "$R/etc/systemd/system/multi-user.target.wants/rgds-pad2key.service"
ln -sf /dev/null "$R/etc/systemd/system/rgds-pad2key.service"

echo
echo "================ VERIFY ================"
echo "-- dtbs --"
ls -l "$B/dtb/rockchip/rk3566-miyoo-flip"*.dtb | awk '{print "  "$5" "$9}'
echo "-- services --"
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|usb-gadget|dnsmasq|ssh' | sed 's/^/  /'
echo "-- disabled --"
ls -l "$R/etc/systemd/system/rgds-pad2key.service" | sed 's/^/  /'
echo "-- modules --"
ls "$R/lib/modules/$REL/extra/" | sed 's/^/  /'
echo "-- hostname --"
cat "$R/etc/hostname" | sed 's/^/  /'
echo "-- padmouse syntax --"
python3 -c "import ast;ast.parse(open('$R/usr/local/bin/miyoo-padmouse').read())" && echo "  ok"
echo "-- disk --"
df -h "$R" | tail -1

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
echo V5_DONE
