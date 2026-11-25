#!/bin/bash
# Walk the Qt5 xcb plugin dependency chain and report anything missing.
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
R=/mnt/miyoo-root
L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mount "${L}p2" "$R"
LIBDIR="$R/usr/lib/aarch64-linux-gnu"

check() {
    local f="$1"
    [ -f "$f" ] || { echo "  (absent) $f"; return; }
    for lib in $(objdump -p "$f" 2>/dev/null | grep NEEDED | sed 's/.*NEEDED *//'); do
        if [ -e "$LIBDIR/$lib" ]; then
            :
        else
            echo "  MISSING $lib   <- needed by $(basename "$f")"
        fi
    done
}

for f in \
    "$LIBDIR/qt5/plugins/platforms/libqxcb.so" \
    "$LIBDIR/libQt5XcbQpa.so.5" \
    "$LIBDIR/libQt5Gui.so.5" \
    "$LIBDIR/libQt5Widgets.so.5" \
    "$LIBDIR/libxkbcommon-x11.so.0" \
    "$LIBDIR/libxcb-xinerama.so.0" \
    "$LIBDIR/libxcb-icccm.so.4" \
    "$LIBDIR/libxcb-image.so.0" \
    "$LIBDIR/libxcb-keysyms.so.1" \
    "$LIBDIR/libxcb-render-util.so.0" \
    "$LIBDIR/libxcb-xkb.so.1"
do
    check "$f"
done
echo "=== end of missing list ==="
echo
echo "=== what IS in libdir matching xcb/xkb ==="
ls "$LIBDIR" | grep -E 'libxcb|xkbcommon' | sort | head -40
sync; umount "$R"; losetup -d "$L"
