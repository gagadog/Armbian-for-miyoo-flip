#!/bin/bash
# 核对 v7 镜像内容
set -e
. "$(dirname "$0")/env.sh"
R=/mnt/miyoo-root
B=/mnt/miyoo-boot
REL=7.3.5-edge-rockchip64

mountpoint -q "$R" && umount "$R" || true
mountpoint -q "$B" && umount "$B" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p1" "$B"
mount "${L}p2" "$R"

echo "=== 1. 密钥必须为空 ==="
if [ -e "$R/home/miyoo/.ssh" ] || [ -e "$R/root/.ssh" ]; then
    echo "  FAIL: .ssh still present"
else
    echo "  OK: no .ssh anywhere"
fi

echo "=== 2. 面板插件 ==="
grep -oE 'name="plugin-[0-9]+" type="string" value="[^"]+"' \
    "$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
    | grep -E 'power-manager|pulseaudio|systray' | sed 's/^/  /'
echo "  plugin-12 应不存在: $(grep -c 'plugin-12' "$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" || true)"
echo "  pulseaudio 插件包应已卸载: $(grep -c '^Package: xfce4-pulseaudio-plugin$' "$R/var/lib/dpkg/status" || true)"

echo "=== 3. 图形化 WiFi / 工具 ==="
for b in nm-applet lxpolkit pnmixer xfce4-power-manager xfce4-panel onboard antimicrox brightnessctl; do
    printf '  %-22s %s\n' "$b" "$(ls "$R/usr/bin/$b" "$R/usr/sbin/$b" 2>/dev/null | head -1 || echo MISSING)"
done
echo "  /etc/xdg/autostart:"
ls "$R/etc/xdg/autostart/" | grep -Ei 'nm-applet|lxpolkit|pnmixer|power' | sed 's/^/    /'
echo "  ~/.config/autostart:"
ls "$R/home/miyoo/.config/autostart/" | sed 's/^/    /'
echo "  桌面图标:"
ls "$R/home/miyoo/Desktop/" | sed 's/^/    /'

echo "=== 4. 音频状态 (Playback Mux) ==="
grep -A4 '"Playback Mux"' "$R/var/lib/alsa/asound.state" 2>/dev/null | grep -E 'name|value' | sed 's/^/  /'

echo "=== 5. 模块 / DTB / 服务 ==="
ls "$R/lib/modules/$REL/extra/" | sed 's/^/  extra: /'
ls "$R/lib/modules/$REL/kernel/drivers/net/wireless/" | sed 's/^/  wifi: /'
grep fdtfile "$B/armbianEnv.txt" | sed 's/^/  /'
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'padmouse|lid|usb-gadget|dnsmasq|ssh|alsa' | sed 's/^/  svc: /'

echo "=== 6. 身份 ==="
echo "  hostname: $(cat "$R/etc/hostname")"
grep BOARD_NAME "$R/etc/armbian-release" | sed 's/^/  /'

echo "=== 7. 磁盘 ==="
df -h "$R" | tail -1

sync
umount "$B"
umount "$R"
losetup -d "$L"
echo VERIFY_V7_DONE
