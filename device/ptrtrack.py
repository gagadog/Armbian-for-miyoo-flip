#!/usr/bin/env python3
"""Track the X pointer position and list input devices, for 40 seconds.

Used to verify that a gamepad button press really reaches the pointer through
antimicrox -> uinput -> X.
"""
import ctypes, os, time, glob

x11 = ctypes.CDLL("libX11.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XDefaultRootWindow.restype = ctypes.c_ulong
x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]

dpy = x11.XOpenDisplay(b":0")
log = open("/tmp/ptr.log", "w", buffering=1)

if not dpy:
    log.write("ERROR: cannot open display :0\n")
    raise SystemExit(1)

root = x11.XDefaultRootWindow(ctypes.c_void_p(dpy))

def pointer():
    rr = ctypes.c_ulong(); cr = ctypes.c_ulong()
    rx = ctypes.c_int(); ry = ctypes.c_int()
    wx = ctypes.c_int(); wy = ctypes.c_int()
    m = ctypes.c_uint()
    ok = x11.XQueryPointer(ctypes.c_void_p(dpy), ctypes.c_ulong(root),
                           ctypes.byref(rr), ctypes.byref(cr),
                           ctypes.byref(rx), ctypes.byref(ry),
                           ctypes.byref(wx), ctypes.byref(wy),
                           ctypes.byref(m))
    return (rx.value, ry.value) if ok else None

def devices():
    out = []
    for p in sorted(glob.glob("/dev/input/event*")):
        try:
            name = open(os.path.join(p, "device/name")).read().strip()
            out.append(f"{os.path.basename(p)}={name}")
        except Exception:
            pass
    return out

log.write("devices: " + " | ".join(devices()) + "\n")

start = time.time()
last = None
while time.time() - start < 40:
    p = pointer()
    if p and p != last:
        log.write(f"{time.time()-start:5.1f}s  pointer={p}\n")
        last = p
    time.sleep(0.15)
log.write("done, final=%s\n" % (last,))
