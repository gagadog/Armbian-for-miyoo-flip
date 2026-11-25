#!/bin/sh
# Install the joypad module + DTB variant and switch the default device tree.
set -e
REL=7.3.5-edge-rockchip64

echo "=== vermagic check ==="
python3 - <<'PY'
import glob
d = open('/tmp/rocknix-singleadc-joypad.ko','rb').read()
i = d.find(b'vermagic=')
print("module :", d[i:i+120].split(b'\x00')[0].decode())
ref = None
for pat in ('/lib/modules/7.3.5-edge-rockchip64/kernel/sound/usb/*/*.ko',
            '/lib/modules/7.3.5-edge-rockchip64/kernel/drivers/gpu/drm/*.ko'):
    g = glob.glob(pat)
    if g:
        ref = sorted(g)[0]
        break
if ref:
    r = open(ref,'rb').read()
    j = r.find(b'vermagic=')
    print("kernel :", r[j:j+120].split(b'\x00')[0].decode())
else:
    print("kernel : (no reference module found)")
PY

echo "=== install DTB ==="
install -m 644 /tmp/rk3566-miyoo-flip-joypad.dtb /boot/dtb/rockchip/rk3566-miyoo-flip-joypad.dtb
ls -l /boot/dtb/rockchip/rk3566-miyoo-flip*.dtb

echo "=== install module ==="
install -D -m 644 /tmp/rocknix-singleadc-joypad.ko \
        /lib/modules/$REL/extra/rocknix-singleadc-joypad.ko
depmod -a $REL
modinfo -F vermagic /lib/modules/$REL/extra/rocknix-singleadc-joypad.ko 2>/dev/null || true
grep -c rocknix /lib/modules/$REL/modules.dep || true
echo "rocknix-singleadc-joypad" > /etc/modules-load.d/rocknix-joypad.conf

echo "=== switch default DTB ==="
sed -i 's|^fdtfile=.*|fdtfile=rockchip/rk3566-miyoo-flip-joypad.dtb|' /boot/armbianEnv.txt
grep -E '^(fdtfile|extraargs)' /boot/armbianEnv.txt

echo "=== rebooting ==="
sync
reboot
