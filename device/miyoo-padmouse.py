#!/usr/bin/env python3
"""
miyoo-padmouse — gamepad to mouse/keyboard mapper for the Miyoo Flip.

Replaces the antimicrox profile for everyday desktop use: it reads the
rocknix-singleadc-joypad device directly and synthesises a mouse plus a few
keys through uinput.

Mapping
    left stick        pointer (quadratic curve + deadzone, so small movements
                      are fine-grained and full deflection is fast)
    right stick       scroll wheel (vertical) and horizontal scroll
    A / B             left / right click
    X / Y             Esc / Enter
    D-pad             arrow keys
    START / SELECT    Enter / Esc
    L1 / R1           PageUp / PageDown
    L2 / R2           Backspace / Delete
    L3 / R3           Space / Tab
    F (MODE)          Super (opens the XFCE menu)

Runs as a system service; uinput is global so no X session access is needed.
"""

import glob
import os
import select
import sys
import time

import evdev
from evdev import UInput, ecodes as e

PAD_NAME = "retrogame_joypad"

# --- action bar -------------------------------------------------------------
# stick tuning
DEADZONE = 6000          # raw units, on top of the driver's own 4914
MAX_SPEED = 14.0         # px per 10 ms tick at full deflection (~1400 px/s)
TICK = 0.010             # seconds
SCROLL_THRESHOLD = 20000
SCROLL_INTERVAL = 0.12   # seconds between wheel clicks
SCROLL_MAX_REPEAT = 1

BUTTON_MAP = {
    e.BTN_SOUTH:   ("mouse", e.BTN_LEFT),
    e.BTN_EAST:    ("mouse", e.BTN_RIGHT),
    e.BTN_NORTH:   ("key", e.KEY_ESC),
    e.BTN_WEST:    ("key", e.KEY_ENTER),
    e.BTN_SELECT:  ("key", e.KEY_ESC),
    e.BTN_START:   ("key", e.KEY_ENTER),
    e.BTN_DPAD_UP:    ("key", e.KEY_UP),
    e.BTN_DPAD_DOWN:  ("key", e.KEY_DOWN),
    e.BTN_DPAD_LEFT:  ("key", e.KEY_LEFT),
    e.BTN_DPAD_RIGHT: ("key", e.KEY_RIGHT),
    e.BTN_TL:      ("key", e.KEY_PAGEUP),
    e.BTN_TR:      ("key", e.KEY_PAGEDOWN),
    e.BTN_TL2:     ("key", e.KEY_BACKSPACE),
    e.BTN_TR2:     ("key", e.KEY_DELETE),
    e.BTN_THUMBL:  ("key", e.KEY_SPACE),
    e.BTN_THUMBR:  ("key", e.KEY_TAB),
    e.BTN_MODE:    ("key", e.KEY_LEFTMETA),
}


def log(msg):
    sys.stderr.write("miyoo-padmouse: %s\n" % msg)
    sys.stderr.flush()


def find_pad():
    forced = os.environ.get("MIYOO_PAD")
    if forced:
        try:
            d = evdev.InputDevice(forced)
            return d
        except Exception:
            pass
    for path in sorted(glob.glob("/dev/input/event*")):
        try:
            d = evdev.InputDevice(path)
        except Exception:
            continue
        caps = d.capabilities()
        if d.name == PAD_NAME and 3 in caps and e.ABS_X in dict(caps[3]):
            return d
        if 3 in caps and e.ABS_X in dict(caps[3]) and 17 <= len(caps.get(1, [])) <= 30:
            return d
    return None


def make_uinput():
    return UInput(
        {
            e.EV_KEY: [
                e.BTN_LEFT, e.BTN_RIGHT,
                e.KEY_UP, e.KEY_DOWN, e.KEY_LEFT, e.KEY_RIGHT,
                e.KEY_ENTER, e.KEY_ESC, e.KEY_PAGEUP, e.KEY_PAGEDOWN,
                e.KEY_BACKSPACE, e.KEY_DELETE, e.KEY_SPACE, e.KEY_TAB,
                e.KEY_LEFTMETA,
            ],
            e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL, e.REL_HWHEEL],
        },
        name="miyoo-padmouse",
        vendor=0x484B, product=0x1102, version=0x0100, bustype=e.BUS_USB,
    )


def axis_speed(v):
    """Quadratic response so small deflections move the pointer slowly."""
    if abs(v) < DEADZONE:
        return 0.0
    sign = 1.0 if v > 0 else -1.0
    norm = (abs(v) - DEADZONE) / (32767.0 - DEADZONE)
    return sign * norm * norm * MAX_SPEED


def main():
    dev = None
    while dev is None:
        dev = find_pad()
        if dev is None:
            log("waiting for %s" % PAD_NAME)
            time.sleep(2)

    log("using %s (%s)" % (dev.path, dev.name))
    ui = make_uinput()
    log("virtual mouse %s" % ui.device.path)

    lx = ly = 0
    acc_x = acc_y = 0.0
    last_scroll_v = last_scroll_h = 0.0
    scroll_v_time = scroll_h_time = 0.0

    try:
        while True:
            r, _, _ = select.select([dev.fd], [], [], TICK)
            if r:
                try:
                    for ev in dev.read():
                        if ev.type == e.EV_ABS:
                            if ev.code == e.ABS_X:
                                lx = ev.value
                            elif ev.code == e.ABS_Y:
                                ly = ev.value
                            elif ev.code == e.ABS_RX:
                                lx_h = ev.value
                                now = time.time()
                                if abs(lx_h) > SCROLL_THRESHOLD and now - scroll_h_time > SCROLL_INTERVAL:
                                    ui.write(e.EV_REL, e.REL_HWHEEL, 1 if lx_h > 0 else -1)
                                    ui.syn()
                                    scroll_h_time = now
                            elif ev.code == e.ABS_RY:
                                ly_v = ev.value
                                now = time.time()
                                if abs(ly_v) > SCROLL_THRESHOLD and now - scroll_v_time > SCROLL_INTERVAL:
                                    ui.write(e.EV_REL, e.REL_WHEEL, -1 if ly_v > 0 else 1)
                                    ui.syn()
                                    scroll_v_time = now
                        elif ev.type == e.EV_KEY:
                            act = BUTTON_MAP.get(ev.code)
                            if act:
                                kind, code = act
                                ui.write(e.EV_KEY, code, ev.value)
                                ui.syn()
                except OSError:
                    log("device disappeared, rescanning")
                    dev = None
                    while dev is None:
                        dev = find_pad()
                        time.sleep(2)
                    log("using %s (%s)" % (dev.path, dev.name))

            # pointer motion, integrated every tick for smooth movement
            sx = axis_speed(lx)
            sy = axis_speed(ly)
            if sx or sy:
                acc_x += sx * (TICK / 0.010)
                acc_y += sy * (TICK / 0.010)
                ix = int(acc_x)
                iy = int(acc_y)
                if ix or iy:
                    acc_x -= ix
                    acc_y -= iy
                    ui.write(e.EV_REL, e.REL_X, ix)
                    ui.write(e.EV_REL, e.REL_Y, iy)
                    ui.syn()
            else:
                acc_x = acc_y = 0.0
    except KeyboardInterrupt:
        pass
    finally:
        ui.close()


if __name__ == "__main__":
    main()
