#!/bin/sh
echo "=== full capabilities of retrogame_joypad ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    if 'retro' not in d.name.lower():
        continue
    c = d.capabilities(absinfo=True)
    print(p, "->", d.name)
    print("  KEY:", len(c.get(1, [])), "codes")
    abs_info = c.get(3, [])
    if not abs_info:
        print("  ABS: (none)")
    for code, info in abs_info:
        print(f"  ABS {evdev.ecodes.ABS[code]}: min={info.min} max={info.max} fuzz={info.fuzz} flat={info.flat}")
PY
echo
echo "=== disable rgds-pad2key (RG DS leftover, superseded by antimicrox) ==="
systemctl disable --now rgds-pad2key.service 2>&1 | tail -3
systemctl is-active rgds-pad2key.service 2>&1 || true
echo
echo "=== listen 6s for stick movement ==="
timeout 8 python3 - <<'PY'
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
if not dev:
    print("no joypad device")
    raise SystemExit(0)
print("watching", dev.path)
lo, hi = {}, {}
end = time.time() + 6
while time.time() < end:
    r, _, _ = select.select([dev.fd], [], [], 0.2)
    if not r:
        continue
    for ev in dev.read():
        if ev.type == 3:
            n = evdev.ecodes.ABS[ev.code]
            lo[n] = min(lo.get(n, ev.value), ev.value)
            hi[n] = max(hi.get(n, ev.value), ev.value)
if not lo:
    print("no ABS events (sticks idle and only report on change?)")
else:
    for n in lo:
        print(f"{n}: {lo[n]} .. {hi[n]}")
PY
