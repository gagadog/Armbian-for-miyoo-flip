#!/bin/bash
set -e
BOOT=/mnt/miyoo-boot
ROOT=/mnt/miyoo-root
REL=7.3.5-edge-rockchip64
OUT="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"

echo "=== sanity: in-tree vermagic ==="
python3 - <<'EOF'
import glob
f=sorted(glob.glob("/mnt/miyoo-root/lib/modules/7.3.5-edge-rockchip64/kernel/sound/usb/*/*.ko"))[0]
d=open(f,'rb').read()
i=d.find(b'vermagic=')
print("ref:", d[i:i+120].split(b'\x00')[0].decode())
f2="/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.ko"
d=open(f2,'rb').read()
i=d.find(b'vermagic=')
print("ours:", d[i:i+120].split(b'\x00')[0].decode())
EOF

echo "=== 1. DTB ==="
cp "$OUT/rk3566-miyoo-flip-armbian-7.3.dtb" "$BOOT/dtb/rockchip/rk3566-miyoo-flip.dtb"
ls -l "$BOOT/dtb/rockchip/rk3566-miyoo-flip.dtb"

echo "=== 2. armbianEnv.txt ==="
cp -n "$BOOT/armbianEnv.txt" "$OUT/armbianEnv.txt.original"
sed -i 's|^fdtfile=.*|fdtfile=rockchip/rk3566-miyoo-flip.dtb|' "$BOOT/armbianEnv.txt"
cat "$BOOT/armbianEnv.txt"

echo "=== 3. panel module ==="
install -D -m 644 "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.ko" \
        "$ROOT/lib/modules/$REL/extra/panel-generic-dsi.ko"
ls -l "$ROOT/lib/modules/$REL/extra/"

echo "=== 4. autoload ==="
mkdir -p "$ROOT/etc/modules-load.d"
printf '# Miyoo Flip FT8006M DSI panel (ROCKNIX generic-dsi driver)\npanel-generic-dsi\n' \
    > "$ROOT/etc/modules-load.d/panel-generic-dsi.conf"
cat "$ROOT/etc/modules-load.d/panel-generic-dsi.conf"

echo "=== 5. depmod ==="
depmod -b "$ROOT" "$REL" 2>&1 | head -10 || true
echo "--- dep entry ---"
grep 'panel-generic-dsi' "$ROOT/lib/modules/$REL/modules.dep" || echo "NO DEP ENTRY"
echo
echo "=== 6. flush ==="
sync
echo OK
