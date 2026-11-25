#!/bin/sh
# Install the mapper as a service and verify it end to end with a synthetic pad.
set -e
echo "=== install ==="
install -m 755 /tmp/miyoo-padmouse.py /usr/local/bin/miyoo-padmouse
python3 -c "import ast,sys; ast.parse(open('/usr/local/bin/miyoo-padmouse').read())" && echo "syntax ok"

cat > /etc/systemd/system/miyoo-padmouse.service <<'EOF'
[Unit]
Description=Miyoo Flip gamepad to mouse/keyboard mapper
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/miyoo-padmouse
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# antimicrox would fight for the same buttons
rm -f /home/miyoo/.config/autostart/antimicrox.desktop
pkill -f antimicrox-logged 2>/dev/null || true
pkill -f 'antimicrox --profile' 2>/dev/null || true

ln -sf /etc/systemd/system/miyoo-padmouse.service \
       /etc/systemd/system/multi-user.target.wants/miyoo-padmouse.service

echo
echo "=== install test pad helper ==="
cat > /tmp/fakepad.py <<'EOF'
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
time.sleep(1)
ui.write(e.EV_ABS, e.ABS_X, 30000); ui.syn()
time.sleep(1.5)
ui.write(e.EV_ABS, e.ABS_X, 0); ui.syn()
time.sleep(0.5)
ui.write(e.EV_KEY, e.BTN_SOUTH, 1); ui.syn()
time.sleep(0.2)
ui.write(e.EV_KEY, e.BTN_SOUTH, 0); ui.syn()
time.sleep(0.5)
ui.close()
EOF

echo
echo "=== end-to-end test ==="
python3 - <<'PY'
import subprocess, threading, time, ctypes, os, sys

x11 = ctypes.CDLL("libX11.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XDefaultRootWindow.restype = ctypes.c_ulong
x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
dpy = x11.XOpenDisplay(b":0")
if not dpy:
    print("no display :0 -- test needs the desktop session")
    sys.exit(1)
root = x11.XDefaultRootWindow(ctypes.c_void_p(dpy))

def pointer():
    rr=ctypes.c_ulong(); cr=ctypes.c_ulong(); rx=ctypes.c_int(); ry=ctypes.c_int()
    wx=ctypes.c_int(); wy=ctypes.c_int(); m=ctypes.c_uint()
    ok = x11.XQueryPointer(ctypes.c_void_p(dpy), ctypes.c_ulong(root),
        ctypes.byref(rr), ctypes.byref(cr), ctypes.byref(rx), ctypes.byref(ry),
        ctypes.byref(wx), ctypes.byref(wy), ctypes.byref(m))
    return (rx.value, ry.value) if ok else None

# start fake pad, learn its node
p = subprocess.Popen([sys.executable, "/tmp/fakepad.py"], stdout=subprocess.PIPE, text=True)
node = p.stdout.readline().strip()
print("fake pad:", node)
time.sleep(1.2)

before = pointer()
print("pointer before:", before)

env = dict(os.environ, MIYOO_PAD=node, DISPLAY=":0",
           XAUTHORITY="/home/miyoo/.Xauthority")
d = subprocess.Popen([sys.executable, "/usr/local/bin/miyoo-padmouse"], env=env,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(3.5)

after = pointer()
print("pointer after :", after)
print("delta:", None if not (before and after) else (after[0]-before[0], after[1]-before[1]))

d.terminate()
try:
    p.wait(timeout=5)
except Exception:
    p.kill()
PY
