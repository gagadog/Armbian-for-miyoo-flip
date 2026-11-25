#!/usr/bin/env python3
"""Log joystick ABS values for 30s so a human can wiggle the sticks."""
import glob, evdev, select, time

dev = None
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    if 'retro' in d.name.lower():
        dev = d
        break

out = open('/tmp/stick.log', 'w', buffering=1)
if not dev:
    out.write("no joypad device\n")
    raise SystemExit(1)

out.write(f"watching {dev.path} {dev.name}\n")
lo, hi = {}, {}
end = time.time() + 30
while time.time() < end:
    r, _, _ = select.select([dev.fd], [], [], 0.2)
    if not r:
        continue
    try:
        for ev in dev.read():
            if ev.type == 3:
                n = evdev.ecodes.ABS[ev.code]
                lo[n] = min(lo.get(n, ev.value), ev.value)
                hi[n] = max(hi.get(n, ev.value), ev.value)
    except Exception:
        pass

if not lo:
    out.write("no ABS events at all\n")
else:
    for n in sorted(lo):
        out.write(f"{n}: {lo[n]} .. {hi[n]}\n")
out.write("done\n")
