#!/bin/bash
# Add the lid daemon to the image and pack v6.
set -e
set -o pipefail

IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v6.img.xz"
DEV="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
R=/mnt/miyoo-root

echo "=== mount ==="
mountpoint -q "$R" && umount "$R" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p2" "$R"

echo "=== lid daemon ==="
install -m 755 "$DEV/miyoo-lid.py" "$R/usr/local/bin/miyoo-lid"
cat > "$R/etc/systemd/system/miyoo-lid.service" <<'EOF'
[Unit]
Description=Miyoo Flip lid switch (backlight off on close)
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/miyoo-lid
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/miyoo-lid.service \
       "$R/etc/systemd/system/multi-user.target.wants/miyoo-lid.service"
mkdir -p "$R/etc/systemd/logind.conf.d"
cat > "$R/etc/systemd/logind.conf.d/miyoo-lid.conf" <<'EOF'
# The suspend path is not wired up on mainline for this board, so logind must
# not suspend when the lid closes.  miyoo-lid.service blanks the backlight.
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

echo
echo "================ VERIFY ================"
echo "-- lid --"
ls -l "$R/usr/local/bin/miyoo-lid" | awk '{print "  "$5" bytes"}'
python3 -c "import ast;ast.parse(open('$R/usr/local/bin/miyoo-lid').read())" && echo "  syntax ok"
ls -l "$R/etc/systemd/system/multi-user.target.wants/miyoo-lid.service" | sed 's/^/  /'
echo "-- all services --"
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|lid|usb-gadget|dnsmasq|ssh' | sed 's/^/  /'
echo "-- wifi --"
ls -l "$R/lib/modules/7.3.5-edge-rockchip64/kernel/drivers/net/wireless/8733bu.ko" | awk '{print "  "$5" bytes"}'
echo "-- disk --"
df -h "$R" | tail -1

sync
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
