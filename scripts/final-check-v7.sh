#!/bin/bash
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mountpoint -q "$R" && umount "$R" || true
mount "${L}p2" "$R"

echo "=== keys ==="
find "$R/home" "$R/root" -name authorized_keys 2>/dev/null | head || true
[ -d "$R/home/miyoo/.ssh" ] && echo "  FAIL: .ssh exists" || echo "  OK: no .ssh"

echo "=== pulseaudio plugin .so ==="
ls "$R/usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpulseaudio-plugin.so" 2>&1 | tail -1
ls "$R/usr/share/xfce4/panel/plugins/pulseaudio.desktop" 2>&1 | tail -1

echo "=== panel config ==="
grep -c 'plugin-12' "$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" || true
grep -oE 'value="power-manager-plugin"' "$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

echo "=== miyoo-lid 兜底代码 ==="
grep -c 'backlight was 0 at start' "$R/usr/local/bin/miyoo-lid" || echo "  MISSING FIX"

echo "=== asound mux ==="
grep -A2 'Playback Mux' "$R/var/lib/alsa/asound.state" | head -3

echo "=== 工具 ==="
for b in pnmixer nm-applet lxpolkit; do
    printf '  %-12s %s\n' "$b" "$(ls "$R/usr/bin/$b" 2>/dev/null || echo MISSING)"
done

sync
umount "$R"
losetup -d "$L"
echo FINAL_OK
