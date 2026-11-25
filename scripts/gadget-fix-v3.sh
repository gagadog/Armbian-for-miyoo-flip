#!/bin/bash
# Replace the boot-time-only gadget with a supervisory loop, then verify + pack.
set -e
set -o pipefail
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v3.img.xz"
R=/mnt/miyoo-root
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mountpoint -q "$R" || mount "${L}p2" "$R"

echo "=== write gadget supervisor ==="
cat > "$R/usr/local/sbin/miyoo-usb-gadget" <<'EOF'
#!/bin/sh
# Keep the Flip exposed as a USB Ethernet (RNDIS) adapter.
#
# The dwc3 controller only registers a UDC while it is in peripheral role,
# i.e. while a host supplies VBUS.  So this runs as a small supervisor:
# it builds the configfs skeleton once, then binds/rebinds whenever a UDC
# shows up (cable plugged in, or role switched back from host).
G=/sys/kernel/config/usb_gadget/miyoo
ADDR=192.168.42.1/24

setup() {
    [ -d /sys/kernel/config/usb_gadget ] || return 1
    modprobe libcomposite 2>/dev/null
    [ -d "$G" ] && return 0
    mkdir -p "$G" || return 1
    echo 0x1d6b > "$G/idVendor"
    echo 0x0104 > "$G/idProduct"
    echo 0x0200 > "$G/bcdUSB"
    echo 0x0100 > "$G/bcdDevice"
    mkdir -p "$G/strings/0x409"
    echo Miyoo        > "$G/strings/0x409/manufacturer"
    echo "Miyoo Flip" > "$G/strings/0x409/product"
    echo flip0001     > "$G/strings/0x409/serialnumber"
    mkdir -p "$G/configs/c.1/strings/0x409"
    echo RNDIS > "$G/configs/c.1/strings/0x409/configuration"
    echo 250   > "$G/configs/c.1/MaxPower"
    mkdir -p "$G/functions/rndis.usb0"
    echo 02:00:00:00:00:02 > "$G/functions/rndis.usb0/dev_addr"  2>/dev/null
    echo 02:00:00:00:00:01 > "$G/functions/rndis.usb0/host_addr" 2>/dev/null
    ln -sf "$G/functions/rndis.usb0" "$G/configs/c.1/" 2>/dev/null
    # Microsoft OS descriptors so Windows binds its RNDIS driver by itself
    mkdir -p "$G/os_desc/interface.rndis"
    echo 1       > "$G/os_desc/use"           2>/dev/null
    echo 0xcd    > "$G/os_desc/b_vendor_code" 2>/dev/null
    echo MSFT100 > "$G/os_desc/qw_sign"       2>/dev/null
    ln -sf "$G/configs/c.1" "$G/os_desc" 2>/dev/null
}

tick() {
    setup || return 0

    udc=$(ls /sys/class/udc 2>/dev/null | head -1)
    if [ -n "$udc" ]; then
        cur=$(cat "$G/UDC" 2>/dev/null || true)
        if [ "$cur" != "$udc" ]; then
            if echo "$udc" > "$G/UDC" 2>/dev/null; then
                echo "miyoo-usb-gadget: bound $udc"
            fi
        fi
    fi

    if [ -d /sys/class/net/usb0 ]; then
        ip link set usb0 up 2>/dev/null || true
        ip addr add "$ADDR" dev usb0 2>/dev/null || true
        if [ ! -f /run/miyoo-usb0.ready ]; then
            : > /run/miyoo-usb0.ready
            echo "miyoo-usb-gadget: usb0 up with $ADDR"
            systemctl try-restart dnsmasq 2>/dev/null &
        fi
    else
        rm -f /run/miyoo-usb0.ready 2>/dev/null || true
    fi
}

case "${1:-loop}" in
    once) setup; tick ;;
    loop) while :; do tick; sleep 3; done ;;
esac
EOF
chmod +x "$R/usr/local/sbin/miyoo-usb-gadget"

cat > "$R/etc/systemd/system/miyoo-usb-gadget.service" <<'EOF'
[Unit]
Description=Miyoo Flip USB RNDIS network gadget
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/usr/local/sbin/miyoo-usb-gadget loop
Restart=always
RestartSec=5
Nice=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== dnsmasq robustness ==="
mkdir -p "$R/etc/systemd/system/dnsmasq.service.d"
cat > "$R/etc/systemd/system/dnsmasq.service.d/10-usb0.conf" <<'EOF'
[Unit]
After=miyoo-usb-gadget.service
[Service]
Restart=always
RestartSec=3
EOF

echo "=== sanity: shell syntax of the gadget script ==="
sh -n "$R/usr/local/sbin/miyoo-usb-gadget" && echo "  syntax ok"
grep -c . "$R/usr/local/sbin/miyoo-usb-gadget"

echo
echo "================ VERIFY ================"
mountpoint -q /mnt/miyoo-boot || mount "${L}p1" /mnt/miyoo-boot
echo "dtb:  $(ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb | awk '{print $5" bytes"}')"
echo "env:  $(grep fdtfile /mnt/miyoo-boot/armbianEnv.txt)"
echo "panel: $(ls -l "$R/lib/modules/7.3.5-edge-rockchip64/extra/" | tail -1 | awk '{print $5" bytes"}')"
echo "vulkan: $(ls "$R/usr/share/vulkan/icd.d/panfrost_icd.json")"
echo "enabled:"
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'ssh|lightdm|dnsmasq|gadget' | sed 's/^/  /'
echo "ssh pubkey: $(wc -c < "$R/home/miyoo/.ssh/authorized_keys") bytes"
df -h "$R" | tail -1

sync
umount /mnt/miyoo-boot 2>/dev/null || true
umount "$R"
losetup -d "$L"

echo "================ PACK ================"
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
echo V3_PACK_DONE
