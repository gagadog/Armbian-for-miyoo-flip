#!/usr/bin/env python3
"""Watch every input device for REL_X/REL_Y (pointer motion).

Usage: relwatch.py [seconds]   (default 40)
"""
import glob, sys, evdev, select, time

dur = int(sys.argv[1]) if len(sys.argv) > 1 else 40

devs = {}
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
        if 2 in d.capabilities():      # EV_REL
            devs[d.fd] = d
    except Exception:
        pass

out = open('/tmp/rel.log', 'w', buffering=1)
out.write("duration %ds, devices with REL: %s\n"
          % (dur, ", ".join(d.name for d in devs.values())))

if not devs:
    out.write("no relative-motion devices at all\n")
    raise SystemExit(0)

counts = {}
end = time.time() + dur
while time.time() < end:
    r, _, _ = select.select(list(devs), [], [], 0.3)
    for fd in r:
        d = devs[fd]
        try:
            for ev in d.read():
                if ev.type == 2 and ev.code in (0, 1):
                    counts[d.name] = counts.get(d.name, 0) + abs(ev.value)
        except Exception:
            pass

if not counts:
    out.write("no REL events at all (nothing moved the pointer)\n")
else:
    for n, v in sorted(counts.items()):
        out.write("%s: total |delta| = %d\n" % (n, v))
out.write("done\n")
