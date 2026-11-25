#!/bin/sh
echo "=== joydev devices ==="
ls -l /dev/input/js* 2>&1
echo
echo "=== event0 capabilities ==="
python3 - <<'PY'
import evdev
try:
    d = evdev.InputDevice('/dev/input/event0')
    print("name:", d.name)
    caps = d.capabilities()
    print("EV_KEY count:", len(caps.get(1, [])))
    print("EV_ABS:", caps.get(3, []) or "none")
    print("keys:", [evdev.ecodes.KEY[k] if k < 0x300 else k for k in caps.get(1, [])][:20])
    print("has ABS?", 3 in caps)
except Exception as e:
    print("ERR", e)
PY
echo
echo "=== antimicrox settings ==="
cat /home/miyoo/.config/antimicrox/antimicrox_settings.ini 2>/dev/null | head -40 || echo "no settings file"
echo
echo "=== antimicrox dirs ==="
ls -R /home/miyoo/.config/antimicrox 2>/dev/null | head -20
