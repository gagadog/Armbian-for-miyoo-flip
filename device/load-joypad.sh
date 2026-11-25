#!/bin/sh
REL=7.3.5-edge-rockchip64
set -e

echo "=== stop old instance if any ==="
rmmod rocknix_singleadc_joypad 2>/dev/null || true

echo "=== install module ==="
install -D -m 644 /tmp/rocknix-singleadc-joypad.ko \
        /lib/modules/$REL/extra/rocknix-singleadc-joypad.ko
depmod -a $REL

echo "=== load ==="
modprobe rocknix-singleadc-joypad 2>&1 || true
sleep 2
lsmod | grep -i joypad || echo "NOT LOADED"

echo
echo "=== dmesg (last joypad lines) ==="
dmesg 2>/dev/null | grep -i -E 'joypad|singleadc' | tail -10

echo
echo "=== input devices ==="
for d in /sys/class/input/event*; do
    n=$(cat "$d/device/name" 2>/dev/null)
    echo "  $(basename "$d")  $n"
done
echo
echo "=== js ==="
ls -l /dev/input/js* 2>&1 || true
echo
echo "=== capabilities ==="
python3 - <<'PY'
import glob, evdev
found = False
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
        if 'retro' in d.name.lower() or 'joypad' in d.name.lower():
            found = True
            caps = d.capabilities()
            print(p, "->", d.name)
            print("  EV_KEY:", len(caps.get(1, [])), "buttons")
            print("  EV_ABS:", [evdev.ecodes.ABS[k] for k in caps.get(3, [])])
    except Exception:
        pass
if not found:
    print("no joypad input device found")
PY
