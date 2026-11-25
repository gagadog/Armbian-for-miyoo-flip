#!/usr/bin/env python3
"""End-to-end check of the antimicrox profile, without a human.

Creates a virtual gamepad whose USB ids match the Miyoo joypad driver
(484b:1101) so antimicrox maps it with the same profile, injects events, and
measures whether the X pointer moved.
"""
import ctypes, time, sys
import evdev
from evdev import UInput, ecodes as e, AbsInfo

x11 = ctypes.CDLL("libX11.so.6")
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XDefaultRootWindow.restype = ctypes.c_ulong
x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
dpy = x11.XOpenDisplay(b":0")
if not dpy:
    print("cannot open display")
    sys.exit(1)
root = x11.XDefaultRootWindow(ctypes.c_void_p(dpy))

def pointer():
    rr = ctypes.c_ulong(); cr = ctypes.c_ulong()
    rx = ctypes.c_int(); ry = ctypes.c_int()
    wx = ctypes.c_int(); wy = ctypes.c_int(); m = ctypes.c_uint()
    ok = x11.XQueryPointer(ctypes.c_void_p(dpy), ctypes.c_ulong(root),
                           ctypes.byref(rr), ctypes.byref(cr),
                           ctypes.byref(rx), ctypes.byref(ry),
                           ctypes.byref(wx), ctypes.byref(wy), ctypes.byref(m))
    return (rx.value, ry.value) if ok else None

keys = [e.BTN_SOUTH, e.BTN_EAST, e.BTN_NORTH, e.BTN_WEST, e.BTN_TL, e.BTN_TR,
        e.BTN_TL2, e.BTN_TR2, e.BTN_SELECT, e.BTN_START, e.BTN_MODE,
        e.BTN_THUMBL, e.BTN_THUMBR,
        e.BTN_DPAD_UP, e.BTN_DPAD_DOWN, e.BTN_DPAD_LEFT, e.BTN_DPAD_RIGHT]
absinfo = [(e.ABS_X, AbsInfo(0, -32767, 32767, 48, 48)),
           (e.ABS_Y, AbsInfo(0, -32767, 32767, 48, 48)),
           (e.ABS_RX, AbsInfo(0, -32767, 32767, 48, 48)),
           (e.ABS_RY, AbsInfo(0, -32767, 32767, 48, 48))]

ui = UInput({e.EV_KEY: keys, e.EV_ABS: absinfo},
            name="retrogame_joypad", vendor=0x484b, product=0x1101,
            version=0x0100, bustype=e.BUS_USB)
print("virtual pad created:", ui.device.path, ui.device.name)
time.sleep(3)

before = pointer()
print("pointer before:", before)

# push left stick fully right for ~1.2 s
ui.write(e.EV_ABS, e.ABS_X, 30000); ui.syn()
time.sleep(1.2)
ui.write(e.EV_ABS, e.ABS_X, 0); ui.syn()
time.sleep(0.3)

after = pointer()
print("pointer after :", after)
if before and after:
    print("delta:", after[0] - before[0], after[1] - before[1])

# also exercise a button so the log shows activity
ui.write(e.EV_KEY, e.BTN_DPAD_RIGHT, 1); ui.syn()
time.sleep(0.2)
ui.write(e.EV_KEY, e.BTN_DPAD_RIGHT, 0); ui.syn()
time.sleep(0.5)

ui.close()
print("done")
