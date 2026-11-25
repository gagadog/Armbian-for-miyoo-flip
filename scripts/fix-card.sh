#!/bin/bash
# Fix the gadget setup directly on the SD card's ext4 rootfs.
# Usage: run after inserting the card; it finds the armbi_root partition itself.
set -e
set -o pipefail

SRC="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
[ -f "$SRC/miyoo-usb-gadget" ] || { echo "missing $SRC/miyoo-usb-gadget"; exit 1; }

echo "=== locate rootfs partition ==="
DEV=$(blkid -L armbi_root || true)
if [ -z "$DEV" ]; then
    echo "no partition labelled armbi_root found; block devices:"
    lsblk -o NAME,LABEL,FSTYPE,SIZE | sed 's/^/  /'
    exit 1
fi
echo "  $DEV"
echo "  $(blkid "$DEV")"

R=/mnt/card-root
mkdir -p "$R"
mountpoint -q "$R" && umount "$R"
mount "$DEV" "$R"

echo "=== files before ==="
ls -l "$R/usr/local/sbin/miyoo-usb-gadget" "$R/etc/systemd/system/miyoo-usb-gadget.service" 2>/dev/null || true

echo "=== install gadget script ==="
cp -f "$SRC/miyoo-usb-gadget" "$R/usr/local/sbin/miyoo-usb-gadget"
chmod 755 "$R/usr/local/sbin/miyoo-usb-gadget"
cp -f "$SRC/miyoo-usb-gadget.service" "$R/etc/systemd/system/miyoo-usb-gadget.service"
chmod 644 "$R/etc/systemd/system/miyoo-usb-gadget.service"
sh -n "$R/usr/local/sbin/miyoo-usb-gadget" && echo "  syntax ok"

echo "=== /etc/modules: drop g_serial ==="
if [ -f "$R/etc/modules" ]; then
    sed -i '/^g_serial[[:space:]]*$/d' "$R/etc/modules"
    echo "  remaining: $(tr '\n' ' ' < "$R/etc/modules")"
fi

echo "=== blacklist legacy gadget modules ==="
cat > "$R/etc/modprobe.d/miyoo-gadget.conf" <<'EOF'
# The Armbian RG-DS image loads the legacy g_serial gadget at boot.  It grabs
# the single dwc3 UDC and enumerates as 0525:a4a7 (a bare serial port), which
# blocks the composite ACM+RNDIS gadget in miyoo-usb-gadget.service.
blacklist g_serial
blacklist g_ether
blacklist g_multi
EOF

echo "=== ensure service enabled ==="
WANT="$R/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANT"
ln -sf /etc/systemd/system/miyoo-usb-gadget.service "$WANT/miyoo-usb-gadget.service"
ls -l "$WANT/miyoo-usb-gadget.service"

echo "=== serial getty on the gadget ACM ==="
ln -sf /lib/systemd/system/serial-getty@.service \
       "$R/etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service" 2>/dev/null || true
mkdir -p "$R/etc/systemd/system/getty.target.wants"
ln -sf /lib/systemd/system/serial-getty@.service \
       "$R/etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service"
ls -l "$R/etc/systemd/system/getty.target.wants/" | grep ttyGS0 || true

echo "=== result ==="
ls -l "$R/usr/local/sbin/miyoo-usb-gadget" "$R/etc/systemd/system/miyoo-usb-gadget.service"
grep -c . "$R/etc/modules" 2>/dev/null || echo "0"

sync
umount "$R"
echo CARD_FIXED
