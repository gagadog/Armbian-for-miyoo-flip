#!/bin/sh
echo "=== kernel ==="
uname -r
echo
echo "=== joypad module ==="
lsmod | grep -i joypad || echo "NOT LOADED"
echo
echo "=== dmesg joypad ==="
echo miyoo | sudo -S dmesg 2>/dev/null | grep -i -E 'joypad|singleadc|miyoo' | tail -15
echo
echo "=== input devices ==="
for d in /sys/class/input/event*; do
    n=$(cat "$d/device/name" 2>/dev/null)
    ev=$(basename "$d")
    echo "$ev  $n"
done
echo
echo "=== js devices ==="
ls -l /dev/input/js* 2>&1
echo
echo "=== retrogame_joypad capabilities ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
        if 'joypad' in d.name.lower() or 'retro' in d.name.lower():
            caps = d.capabilities()
            print(p, d.name)
            print("  EV_KEY:", len(caps.get(1, [])))
            print("  EV_ABS:", [evdev.ecodes.ABS[k] for k in caps.get(3, [])])
    except Exception as e:
        pass
PY
echo
echo "=== reading stick for 3 seconds (move it now!) ==="
timeout 5 python3 - <<'PY'
import glob, evdev, time, select
dev = None
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
        if 3 in d.capabilities():
            dev = d
            break
    except Exception:
        pass
if not dev:
    print("no device with ABS axes")
else:
    print("watching", dev.path, dev.name)
    end = time.time() + 4
    seen = {}
    dev.set_blocking(False)
    while time.time() < end:
        r, _, _ = select.select([dev.fd], [], [], 0.2)
        if r:
            try:
                for ev in dev.read():
                    if ev.type == 3:
                        seen[evdev.ecodes.ABS[ev.code]] = ev.value
            except Exception:
                pass
    print("last ABS values:", seen)
PY
