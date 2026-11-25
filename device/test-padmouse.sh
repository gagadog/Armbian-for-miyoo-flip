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
# 6 cycles of "push right, release" so any start time catches it
for i in range(6):
    ui.write(e.EV_ABS, e.ABS_X, 30000); ui.syn()
    time.sleep(0.7)
    ui.write(e.EV_ABS, e.ABS_X, 0); ui.syn()
    time.sleep(0.3)
# then a click
ui.write(e.EV_KEY, e.BTN_SOUTH, 1); ui.syn()
time.sleep(0.2)
ui.write(e.EV_KEY, e.BTN_SOUTH, 0); ui.syn()
time.sleep(0.5)
ui.close()
EOF

python3 /tmp/fakepad2.py > /tmp/fake.node 2>/dev/null &
FAKE=$!
sleep 0.8
NODE=$(head -1 /tmp/fake.node)
echo "fake node: $NODE"

MIYOO_PAD="$NODE" /usr/bin/python3 /usr/local/bin/miyoo-padmouse > /tmp/pm.out 2> /tmp/pm.err &
PM=$!

python3 - <<'PY'
import ctypes, time
x11 = ctypes.CDLL("libX11.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XDefaultRootWindow.restype = ctypes.c_ulong
x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
dpy = x11.XOpenDisplay(b":0")
root = x11.XDefaultRootWindow(ctypes.c_void_p(dpy))
def ptr():
    rr=ctypes.c_ulong(); cr=ctypes.c_ulong(); rx=ctypes.c_int(); ry=ctypes.c_int()
    wx=ctypes.c_int(); wy=ctypes.c_int(); m=ctypes.c_uint()
    x11.XQueryPointer(ctypes.c_void_p(dpy), ctypes.c_ulong(root),
        ctypes.byref(rr), ctypes.byref(cr), ctypes.byref(rx), ctypes.byref(ry),
        ctypes.byref(wx), ctypes.byref(wy), ctypes.byref(m))
    return (rx.value, ry.value)
pts = []
for i in range(20):
    pts.append(ptr())
    time.sleep(0.3)
print("pointer samples:", pts[0], "->", pts[-1])
print("max x:", max(p[0] for p in pts), "min x:", min(p[0] for p in pts))
PY

kill $PM 2>/dev/null
wait $FAKE 2>/dev/null
echo "--- daemon stderr ---"
cat /tmp/pm.err
