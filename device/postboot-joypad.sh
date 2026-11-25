#!/bin/sh
echo "=== joypad dmesg after boot ==="
echo miyoo | sudo -S dmesg 2>/dev/null | grep -iE 'joypad|ttyS1|serial' | tail -15
echo
echo "=== input devices ==="
for d in /sys/class/input/event*; do
    n=$(cat "$d/device/name" 2>/dev/null)
    echo "  $(basename "$d")  $n"
done
echo
echo "=== axes present ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    if 'retro' in d.name.lower():
        c = d.capabilities(absinfo=True)
        print(p, d.name, "keys:", len(c.get(1, [])),
              "abs:", [evdev.ecodes.ABS[k] for k, _ in c.get(3, [])])
PY
