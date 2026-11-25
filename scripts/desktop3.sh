#!/bin/bash
# v3: USB network gadget (so the box can be debugged over a single USB-C cable),
# backlight control, Vulkan (PanVK), and a self-diagnosing antimicrox launcher.
set -e
set -o pipefail
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mountpoint -q "$R" || mount "${L}p2" "$R"
for d in proc sys dev dev/pts; do mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"; done
install -m 755 /usr/bin/qemu-aarch64-static "$R/usr/bin/qemu-aarch64-static"

# /etc/resolv.conf is a symlink to the systemd-resolved stub; mount the host
# resolver onto the *target* so DNS works inside the chroot.
mkdir -p "$R/run/systemd/resolve"
touch "$R/run/systemd/resolve/stub-resolv.conf"
mountpoint -q "$R/run/systemd/resolve/stub-resolv.conf" || \
    mount --bind /etc/resolv.conf "$R/run/systemd/resolve/stub-resolv.conf"
echo "resolv: $(head -1 "$R/etc/resolv.conf" | head -c 0)ok"

cat > "$R/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "$R/usr/sbin/policy-rc.d"

echo "=== packages ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update 2>&1 | tail -3
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      brightnessctl mesa-vulkan-drivers vulkan-tools mesa-utils dnsmasq \
      evtest usbutils strace libinput-tools \
    2>&1 | tail -8

echo "=== ssh debug key ==="
PUB=$(cat "/mnt/d/wendang/默认项目/miyoo-flip-dtb/keys/miyoo_debug.pub")
for u in miyoo root; do
    if [ "$u" = root ]; then H="$R/root"; else H="$R/home/$u"; fi
    mkdir -p "$H/.ssh"
    printf '%s\n' "$PUB" > "$H/.ssh/authorized_keys"
    chmod 700 "$H/.ssh"; chmod 600 "$H/.ssh/authorized_keys"
done
chown -R 1000:1000 "$R/home/miyoo/.ssh"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$R/etc/ssh/sshd_config" || true
grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)' "$R/etc/ssh/sshd_config"

echo "=== backlight permissions ==="
cat > "$R/etc/udev/rules.d/90-backlight-video.rules" <<'EOF'
# let the video group change the panel brightness without root
SUBSYSTEM=="backlight", ACTION=="add", \
  RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

echo "=== USB RNDIS gadget ==="
mkdir -p "$R/usr/local/sbin"
cat > "$R/usr/local/sbin/miyoo-usb-gadget" <<'EOF'
#!/bin/sh
# Present the Flip as a USB Ethernet (RNDIS) adapter so a single USB-C cable
# to a PC gives an SSH-reachable network link.  192.168.42.1 on this side,
# 192.168.42.10-50 handed out by dnsmasq on the PC side.
set -u
G=/sys/kernel/config/usb_gadget/miyoo
IP=192.168.42.1/24

modprobe libcomposite 2>/dev/null || true

if [ ! -d /sys/kernel/config/usb_gadget ]; then
    echo "configfs gadget support missing, giving up" >&2
    exit 0
fi

if [ ! -d "$G" ]; then
    mkdir -p "$G"
    echo 0x1d6b > "$G/idVendor"
    echo 0x0104 > "$G/idProduct"
    echo 0x0200 > "$G/bcdUSB"
    echo 0x0100 > "$G/bcdDevice"
    mkdir -p "$G/strings/0x409"
    echo "Miyoo"          > "$G/strings/0x409/manufacturer"
    echo "Miyoo Flip"     > "$G/strings/0x409/product"
    echo "flip0001"       > "$G/strings/0x409/serialnumber"
    mkdir -p "$G/configs/c.1/strings/0x409"
    echo "RNDIS"          > "$G/configs/c.1/strings/0x409/configuration"
    echo 250              > "$G/configs/c.1/MaxPower"
    mkdir -p "$G/functions/rndis.usb0"
    ln -sf "$G/functions/rndis.usb0" "$G/configs/c.1/" 2>/dev/null || true
fi

UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
if [ -z "$UDC" ]; then
    echo "no UDC: controller is in host mode (unplug the PC, or check dr_mode)" >&2
    exit 0
fi
echo "$UDC" > "$G/UDC" 2>/dev/null || true

for i in $(seq 1 50); do
    [ -d /sys/class/net/usb0 ] && break
    sleep 0.2
done

if [ -d /sys/class/net/usb0 ]; then
    ip link set usb0 up 2>/dev/null || true
    ip addr add "$IP" dev usb0 2>/dev/null || true
    echo "usb0 up with $IP"
else
    echo "usb0 did not appear" >&2
fi
EOF
chmod +x "$R/usr/local/sbin/miyoo-usb-gadget"

cat > "$R/etc/systemd/system/miyoo-usb-gadget.service" <<'EOF'
[Unit]
Description=Miyoo Flip USB RNDIS network gadget
After=systemd-modules-load.service
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/miyoo-usb-gadget
ExecStop=/bin/sh -c 'echo "" > /sys/kernel/config/usb_gadget/miyoo/UDC 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
EOF
chroot "$R" systemctl enable miyoo-usb-gadget.service >/dev/null 2>&1 || true

echo "=== keep NetworkManager off usb0 ==="
mkdir -p "$R/etc/NetworkManager/conf.d"
cat > "$R/etc/NetworkManager/conf.d/99-usb0-unmanaged.conf" <<'EOF'
[keyfile]
unmanaged-devices=interface-name:usb0
EOF

echo "=== dnsmasq on usb0 ==="
mkdir -p "$R/etc/dnsmasq.d"
cat > "$R/etc/dnsmasq.d/usb0.conf" <<'EOF'
interface=usb0
bind-dynamic
dhcp-range=192.168.42.10,192.168.42.50,255.255.255.0,12h
# no gateway and no DNS: the PC keeps its normal routing/internet
dhcp-option=3
dhcp-option=6
EOF
chroot "$R" systemctl enable dnsmasq >/dev/null 2>&1 || true

echo "=== brightness shortcuts ==="
for spec in "up:+10%:亮度 +" "down:10%-:亮度 -"; do
    key=$(echo "$spec" | cut -d: -f1)
    arg=$(echo "$spec" | cut -d: -f2)
    name=$(echo "$spec" | cut -d: -f3)
    cat > "$R/home/miyoo/Desktop/brightness-$key.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=brightnessctl -q set $arg
Icon=display-brightness
Terminal=false
Categories=Utility;
EOF
    chmod +x "$R/home/miyoo/Desktop/brightness-$key.desktop"
done

echo "=== antimicrox wrapper with logging ==="
mkdir -p "$R/home/miyoo/.local/bin"
cat > "$R/home/miyoo/.local/bin/antimicrox-logged" <<'EOF'
#!/bin/sh
# Start antimicrox and keep its stderr, so a silent failure can be diagnosed
# afterwards.  If the saved profile is what kills it, fall back to a clean run.
LOG="$HOME/antimicrox.log"
PROFILE="$HOME/.config/antimicrox/profiles/miyoo-mouse.amgp"
: > "$LOG"
if [ -f "$PROFILE" ]; then
    antimicrox --profile "$PROFILE" --hidden >>"$LOG" 2>&1 &
else
    antimicrox --hidden >>"$LOG" 2>&1 &
fi
PID=$!
sleep 6
if ! kill -0 "$PID" 2>/dev/null; then
    echo "--- first attempt died, retrying without profile ---" >>"$LOG"
    antimicrox --hidden >>"$LOG" 2>&1 &
fi
wait
EOF
chmod +x "$R/home/miyoo/.local/bin/antimicrox-logged"

cat > "$R/home/miyoo/.config/autostart/antimicrox.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=AntiMicroX (mouse mode)
Comment=Map the gamepad to the mouse pointer
Exec=/home/miyoo/.local/bin/antimicrox-logged
Icon=antimicrox
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chroot "$R" chown -R 1000:1000 /home/miyoo
chroot "$R" chmod 700 /home/miyoo

echo "=== result ==="
chroot "$R" bash -c 'for b in brightnessctl vulkaninfo glxinfo dnsmasq; do printf "  %-14s %s\n" "$b" "$(command -v $b || echo MISSING)"; done'
ls "$R/usr/share/vulkan/icd.d/" 2>/dev/null || echo "  no ICD yet"

rm -f "$R/usr/sbin/policy-rc.d" "$R/usr/bin/qemu-aarch64-static"
chroot "$R" apt-get clean || true
rm -rf "$R"/var/lib/apt/lists/*
mkdir -p "$R/var/lib/apt/lists/partial"
sync
for d in dev/pts dev sys proc; do umount "$R/$d" 2>/dev/null || true; done
umount "$R/run/systemd/resolve/stub-resolv.conf" 2>/dev/null || true
umount "$R"; losetup -d "$L"
df -h "$R" 2>/dev/null || true
echo V3_DONE
