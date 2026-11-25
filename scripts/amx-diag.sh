#!/bin/bash
# Diagnose why antimicrox does not start: missing libs, Qt platform plugin,
# or a runtime crash. Runs the arm64 binary through qemu-user.
set -e
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -fP --show "$IMG")
mkdir -p "$R"
mount "${L}p2" "$R"
for d in proc sys dev dev/pts; do mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"; done
cp /usr/bin/qemu-aarch64-static "$R/usr/bin/"

echo "=== package deps ==="
grep -E '^Package: antimicrox$' -A40 "$R/var/lib/dpkg/status" | grep -E '^(Version|Depends|Recommends)' | head -5
echo
echo "=== Qt version linked ==="
chroot "$R" readelf -d /usr/bin/antimicrox 2>/dev/null | grep -oE 'libQt[0-9][A-Za-z]*\.so[^]]*' | sort -u | head
echo
echo "=== missing shared libs ==="
chroot "$R" ldd /usr/bin/antimicrox 2>&1 | grep -i 'not found' || echo "  (none missing)"
echo
echo "=== try to run (offscreen) ==="
chroot "$R" /usr/bin/env QT_QPA_PLATFORM=offscreen HOME=/root \
    timeout 40 /usr/bin/antimicrox --version 2>&1 | head -20
echo "rc=$?"
echo
echo "=== Qt platform plugins present ==="
ls "$R"/usr/lib/aarch64-linux-gnu/qt*/plugins/platforms/ 2>/dev/null
echo
echo "=== xcb related libs ==="
chroot "$R" ldd /usr/lib/aarch64-linux-gnu/qt6/plugins/platforms/libqxcb.so 2>&1 | grep -i 'not found' || echo "  (qxcb deps ok or file absent)"
echo
echo "=== sdl2 joystick backend ==="
chroot "$R" bash -c 'ls /usr/lib/aarch64-linux-gnu/libSDL2* 2>/dev/null; dpkg -s libsdl2-2.0-0 2>/dev/null | grep Version'

sync
umount "$R/dev/pts" 2>/dev/null || true
umount "$R/dev" 2>/dev/null || true
umount "$R/sys" 2>/dev/null || true
umount "$R/proc" 2>/dev/null || true
rm -f "$R/usr/bin/qemu-aarch64-static"
umount "$R"
losetup -d "$L"
