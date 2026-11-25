#!/bin/bash
# v7 = v6 + nm-applet(托盘WiFi) + 面板(电量/音量/亮度) + 音频 mux 修正 - 调试密钥
set -e
set -o pipefail

. "$(dirname "$0")/env.sh"
DST="$ROOT/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz"
DEV="$ROOT/device"
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

echo "=== 1. 安装 nm-applet 栈（含 lxpolkit 认证代理）==="
install -m 755 /usr/bin/qemu-aarch64-static "$R/usr/bin/qemu-aarch64-static"
rm -rf "$R/tmp/debs"; mkdir -p "$R/tmp/debs"
cp "$DEBS"/*.deb "$R/tmp/debs/"
for d in proc sys dev dev/pts; do mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"; done
cat > "$R/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "$R/usr/sbin/policy-rc.d"
chroot "$R" /bin/sh -c 'dpkg -i /tmp/debs/*.deb' 2>&1 | grep -E 'Setting up|error:|depends' | head -20
chroot "$R" /bin/sh -c 'dpkg --configure -a' 2>&1 | tail -4
chroot "$R" /bin/sh -c 'dpkg -C' 2>&1 | head -3 || true

# 音量面板插件在这块板子上会让 xfce4-panel 崩溃（运行时连 pipewire-pulse 失败），
# 直接卸载掉，改用 pnmixer 托盘图标 + 桌面音量按钮
chroot "$R" /bin/sh -c 'dpkg --purge xfce4-pulseaudio-plugin' 2>&1 | grep -E 'Purging|Removing' | head -2 || true

rm -rf "$R/tmp/debs"
rm -f "$R/usr/sbin/policy-rc.d" "$R/usr/bin/qemu-aarch64-static"
for d in dev/pts dev sys proc; do umount "$R/$d" 2>/dev/null || true; done

echo "=== 2. 面板配置（电量/音量/亮度插件）==="
DEST="$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$DEST"
install -m 644 "$DEV/xfce4-panel.xml" "$DEST/xfce4-panel.xml"

# xfce4-power-manager 的 autostart 文件在精简安装里缺失，导致开机没有电量图标
# 和亮度滑条；补一个（有的话覆盖也无害）
cat > "$R/home/miyoo/.config/autostart/xfce4-power-manager.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Power Manager
Comment=Battery, brightness and power settings
Exec=xfce4-power-manager
Icon=xfce4-power-manager
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chown -R 1000:1000 "$R/home/miyoo/.config/xfce4" "$R/home/miyoo/.config/autostart"

echo "=== 2b. 音量：pnmixer 托盘 + 桌面按钮 ==="
cat > "$R/etc/xdg/autostart/pnmixer.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=PNMixer
Comment=Volume control in the system tray
Exec=pnmixer
Icon=pnmixer
Terminal=false
NoDisplay=true
EOF
cat > "$R/home/miyoo/Desktop/volume-up.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=音量 +
Exec=wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
Icon=audio-volume-high
Terminal=false
EOF
cat > "$R/home/miyoo/Desktop/volume-down.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=音量 -
Exec=wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
Icon=audio-volume-low
Terminal=false
EOF
chmod 755 "$R/home/miyoo/Desktop/volume-"*.desktop
chown 1000:1000 "$R/home/miyoo/Desktop/volume-"*.desktop

echo "=== 3. 音频：Playback Mux = SPK ==="
install -D -m 644 "$DEV/asound.state" "$R/var/lib/alsa/asound.state"
grep -A2 'Playback Mux' "$DEV/asound.state" | head -3 | sed 's/^/  /' || true

echo "=== 4. 删除调试 SSH 密钥 ==="
for h in "$R/home/miyoo" "$R/root"; do
    if [ -d "$h/.ssh" ]; then
        echo "  removing $h/.ssh ($(ls "$h/.ssh" | tr '\n' ' '))"
        rm -rf "$h/.ssh"
    fi
done
find "$R/home" "$R/root" -name 'authorized_keys' 2>/dev/null | sed 's/^/  LEFT: /'

echo
echo "================ VERIFY ================"
echo "-- nm-applet / polkit --"
ls -l "$R/usr/bin/nm-applet" 2>/dev/null | awk '{print "  nm-applet: "$5" bytes"}'
ls "$R/usr/bin/lxpolkit" 2>/dev/null | sed 's/^/  /'
ls "$R/etc/xdg/autostart/" | grep -Ei 'nm-applet|lxpolkit|power' | sed 's/^/  autostart: /'
echo "-- panel plugins --"
grep -oE 'name="plugin-[0-9]+" type="string" value="[^"]+"' "$DEST/xfce4-panel.xml" | grep -E 'power-manager|pulseaudio|systray' | sed 's/^/  /'
echo "-- audio state --"
ls -l "$R/var/lib/alsa/asound.state" | awk '{print "  asound.state: "$5" bytes"}'
echo "-- services --"
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|lid|usb-gadget|dnsmasq|ssh' | sed 's/^/  /'
echo "-- keys --"
ls "$R/home/miyoo/.ssh" "$R/root/.ssh" 2>/dev/null || echo "  no .ssh dirs (good)"
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
echo V7_DONE
