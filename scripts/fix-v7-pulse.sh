#!/bin/bash
# Purge xfce4-pulseaudio-plugin from the image (it crashes xfce4-panel on this
# board).  Falls back to removing the plugin .so + registry if dpkg refuses.
set -e
set -o pipefail

. "$(dirname "$0")/env.sh"
DST="$ROOT/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz"
R=/mnt/miyoo-root

mountpoint -q "$R" && umount "$R" || true
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mount "${L}p2" "$R"

echo "=== package state before ==="
grep -c '^Package: xfce4-pulseaudio-plugin$' "$R/var/lib/dpkg/status" || echo "  0"

echo
echo "=== try dpkg --purge in chroot ==="
install -m 755 /usr/bin/qemu-aarch64-static "$R/usr/bin/qemu-aarch64-static"
for d in proc sys dev dev/pts; do mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"; done
cat > "$R/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "$R/usr/sbin/policy-rc.d"
chroot "$R" /bin/sh -c 'dpkg --purge xfce4-pulseaudio-plugin' 2>&1 | tail -8 || true
rm -f "$R/usr/sbin/policy-rc.d" "$R/usr/bin/qemu-aarch64-static"
for d in dev/pts dev sys proc; do umount "$R/$d" 2>/dev/null || true; done

echo
echo "=== still installed? ==="
if grep -q '^Package: xfce4-pulseaudio-plugin$' "$R/var/lib/dpkg/status"; then
    echo "  yes -> removing the plugin binary + registry instead"
    rm -f "$R/usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpulseaudio-plugin.so"
    rm -f "$R/usr/share/xfce4/panel/plugins/pulseaudio.desktop"
    echo "  removed .so and .desktop"
else
    echo "  no, purged cleanly"
fi
ls "$R"/usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/ | tr '\n' ' '
echo

echo "=== config check (plugin-12 must be absent) ==="
grep -c 'plugin-12' "$R/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" || true

sync
umount "$R"
losetup -d "$L"

echo
echo "=== PACK ==="
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
xz -t "$DST/$NAME" && echo "xz OK"
echo FIX_DONE
