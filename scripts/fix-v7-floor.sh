#!/bin/bash
set -e
set -o pipefail

IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz"
DEV="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
R=/mnt/miyoo-root

mountpoint -q "$R" && umount "$R" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p2" "$R"

echo "=== install the updated lid daemon (with the 0-brightness floor) ==="
install -m 755 "$DEV/miyoo-lid.py" "$R/usr/local/bin/miyoo-lid"
grep -c 'backlight was 0 at start' "$R/usr/local/bin/miyoo-lid"
python3 -c "import ast;ast.parse(open('$R/usr/local/bin/miyoo-lid').read())" && echo "  syntax ok"

echo
echo "=== lid bits present? ==="
ls -l "$R/etc/systemd/system/multi-user.target.wants/miyoo-lid.service" | sed 's/^/  /'
cat "$R/etc/systemd/logind.conf.d/miyoo-lid.conf" 2>/dev/null | grep -E '^HandleLidSwitch' | sed 's/^/  /'

echo
echo "=== also drop a floor at boot for the case where no lid daemon runs ==="
cat > "$R/etc/systemd/system/miyoo-brightness-floor.service" <<'EOF'
[Unit]
Description=Ensure the panel backlight is not left at 0
After=systemd-backlight@backlight:backlight.service
Wants=systemd-backlight@backlight:backlight.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'v=$(cat /sys/class/backlight/backlight/brightness); [ "$v" -eq 0 ] && echo 120 > /sys/class/backlight/backlight/brightness || true'

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/miyoo-brightness-floor.service \
       "$R/etc/systemd/system/multi-user.target.wants/miyoo-brightness-floor.service"
ls -l "$R/etc/systemd/system/multi-user.target.wants/miyoo-brightness-floor.service" | sed 's/^/  /'

sync
umount "$R"
losetup -d "$L"

echo
echo "=== PACK ==="
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
xz -t "$DST/$NAME" && echo "xz OK"
echo FLOOR_DONE
