#!/bin/sh
cat > /tmp/fakepad2.py <<'EOF'
import sys, time
import evdev
from evdev import UInput, ecodes as e, AbsInfo
keys = [e.BTN_SOUTH, e.BTN_EAST, e.BTN_NORTH, e.BTN_WEST, e.BTN_TL, e.BTN_TR,
        e.BTN_TL2, e.BTN_TR2, e.BTN_SELECT, e.BTN_START, e.BTN_MODE,
        e.BTN_THUMBL, e.BTN_THUMBR, e.BTN_DPAD_UP, e.BTN_DPAD_DOWN,
        e.BTN_DPAD_LEFT, e.BTN_DPAD_RIGHT]
absinfo = [(c, AbsInfo(0, -32767, 32767, 48, 48, 0))
           for c in (e.ABS_X, e.ABS_Y, e.ABS_RX, e.ABS_RY)]
ui = UInput({e.EV_KEY: keys, e.EV_ABS: absinfo}, name="retrogame_joypad",
            vendor=0x484b, product=0x1101, version=0x0100, bustype=e.BUS_USB)
print(ui.device.path, flush=True)
time.sleep(0.5)
for i in range(8):
    ui.write(e.EV_ABS, e.ABS_X, 30000); ui.syn()
    time.sleep(0.5)
    ui.write(e.EV_ABS, e.ABS_X, 0); ui.syn()
    time.sleep(0.25)
for code in (e.BTN_SOUTH, e.BTN_EAST, e.BTN_DPAD_UP, e.BTN_START, e.BTN_SELECT, e.BTN_MODE):
    ui.write(e.EV_KEY, code, 1); ui.syn()
    time.sleep(0.15)
    ui.write(e.EV_KEY, code, 0); ui.syn()
    time.sleep(0.15)
time.sleep(0.4)
ui.close()
EOF

cat > /tmp/watchout.py <<'EOF'
import glob, select, sys, time
import evdev
from evdev import ecodes as e

dev = None
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    if d.name == 'miyoo-padmouse':
        dev = d
        break
if not dev:
    print("no miyoo-padmouse device")
    sys.exit(1)

print("watching", dev.path)
rel = {}
keys = {}
end = time.time() + 14
while time.time() < end:
    r, _, _ = select.select([dev.fd], [], [], 0.2)
    if not r:
        continue
    for ev in dev.read():
        if ev.type == 2:                     # EV_REL
            rel[ev.code] = rel.get(ev.code, 0) + abs(ev.value)
        elif ev.type == 1 and ev.value == 1:  # EV_KEY press
            keys[ev.code] = keys.get(ev.code, 0) + 1

print("REL codes (0=X 1=Y 8=WHEEL 6=HWHEEL):", rel if rel else "none")
print("KEY codes pressed:", keys if keys else "none")
print()
print("interpretation:")
for c, v in sorted(rel.items()):
    print("  REL %s: total %d" % ({0:'X',1:'Y',6:'HWHEEL',8:'WHEEL'}.get(c, c), v))
for c, v in sorted(keys.items()):
    print("  KEY %s: %d press(es)" % ({272:'BTN_LEFT',273:'BTN_RIGHT',103:'UP',108:'DOWN',
        105:'LEFT',106:'RIGHT',28:'ENTER',1:'ESC',104:'PAGEUP',109:'PAGEDOWN',
        14:'BACKSPACE',111:'DELETE',57:'SPACE',15:'TAB',125:'LEFTMETA'}.get(c, c), v))
EOF

python3 /tmp/fakepad2.py > /tmp/fake.node 2>/dev/null &
FAKE=$!
sleep 0.8
NODE=$(head -1 /tmp/fake.node)
echo "fake node: $NODE"

MIYOO_PAD="$NODE" /usr/bin/python3 /usr/local/bin/miyoo-padmouse > /tmp/pm.out 2> /tmp/pm.err &
PM=$!
sleep 2

python3 /tmp/watchout.py
echo
echo "--- daemon stderr ---"
cat /tmp/pm.err
kill $PM 2>/dev/null
wait $FAKE 2>/dev/null
