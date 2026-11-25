#!/bin/sh
echo "=== headphone jack switch state ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    caps = d.capabilities()
    if 5 in caps and evdev.ecodes.SW_HEADPHONE_INSERT in caps[5]:
        print(" ", p, d.name, "active switches:", d.active_keys())
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    if 'Headphone' in d.name:
        print(" ", d.name, "->", [evdev.ecodes.SW.get(k, k) for k in d.active_keys()])
PY

echo
echo "=== mixer Master range / current ==="
amixer -c 1 sget Master 2>&1 | head -6

echo
echo "=== set Master to 90% ==="
amixer -c 1 sset Master 90% 2>&1 | tail -3

echo
echo "=== play 3s tone (listen!) ==="
timeout 8 aplay -D plughw:1,0 /tmp/tone.wav 2>&1 | tail -3
echo "  rc=$?"

echo
echo "=== also play a 1kHz sine via speaker-test ==="
timeout 6 speaker-test -D plughw:1,0 -c 2 -t sine -f 1000 -l 1 2>&1 | tail -3
