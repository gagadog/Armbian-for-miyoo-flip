#!/usr/bin/env python3
"""
miyoo-lid — lid switch handler for the Miyoo Flip.

The hall sensor is exposed as a plain input device with SW_LID.  Instead of
letting systemd-logind suspend (the suspend path is not wired up on mainline
for this board), this turns the panel backlight off while the lid is closed and
restores the previous level when it opens.

Backlight level is written straight to sysfs, so no X session is involved and it
also works from the console.
"""

import glob
import os
import select
import sys
import time

import evdev
from evdev import ecodes as e

BL_DIR = "/sys/class/backlight"
SAVED = "/run/miyoo-lid.saved"


def log(msg):
    sys.stderr.write("miyoo-lid: %s\n" % msg)
    sys.stderr.flush()


def backlight_path():
    for d in sorted(glob.glob(os.path.join(BL_DIR, "*"))):
        p = os.path.join(d, "brightness")
        if os.path.exists(p):
            return p
    return None


def rd(path):
    with open(path) as f:
        return int(f.read().strip())


def wr(path, val):
    try:
        with open(path, "w") as f:
            f.write("%d\n" % val)
        return True
    except Exception as ex:
        log("write %s=%d failed: %s" % (path, val, ex))
        return False


def max_brightness(bl):
    try:
        return rd(os.path.join(os.path.dirname(bl), "max_brightness"))
    except Exception:
        return 255


def find_lid():
    forced = os.environ.get("MIYOO_LID")
    if forced:
        try:
            return evdev.InputDevice(forced)
        except Exception:
            pass
    for path in sorted(glob.glob("/dev/input/event*")):
        try:
            d = evdev.InputDevice(path)
        except Exception:
            continue
        caps = d.capabilities()
        if 5 in caps and e.SW_LID in caps[5]:       # EV_SW + SW_LID
            return d
    return None


def set_closed(bl, closed):
    if closed:
        if not os.path.exists(SAVED):
            cur = rd(bl)
            if cur > 0:
                with open(SAVED, "w") as f:
                    f.write("%d\n" % cur)
            wr(bl, 0)
            log("lid closed, backlight off (saved %d)" % cur)
    else:
        val = None
        if os.path.exists(SAVED):
            try:
                val = int(open(SAVED).read().strip())
            except Exception:
                val = None
            os.unlink(SAVED)
        if val is None or val <= 0:
            val = max(1, max_brightness(bl) // 2)
        wr(bl, val)
        log("lid open, backlight %d" % val)


def main():
    bl = backlight_path()
    if not bl:
        log("no backlight device, exiting")
        return

    dev = None
    while dev is None:
        dev = find_lid()
        if dev is None:
            log("waiting for a device with SW_LID")
            time.sleep(2)

    log("using %s (%s), backlight %s" % (dev.path, dev.name, bl))

    # sync with the current state once: only act if the lid starts closed,
    # otherwise leave the user's brightness alone
    try:
        state = dev.active_keys()
        if e.SW_LID in state:
            set_closed(bl, True)
    except Exception:
        pass

    # Boot safety net: systemd-backlight saves the current level at shutdown, and
    # if the lid was closed the saved value is 0 -- which would come back as a
    # black screen after the next boot, with no way to recover from the UI.
    # If the lid is open and the panel is dark, bring it up to a usable level.
    try:
        if e.SW_LID not in dev.active_keys() and rd(bl) == 0:
            level = max(1, max_brightness(bl) // 2)
            if wr(bl, level):
                log("backlight was 0 at start, raised to %d" % level)
    except Exception:
        pass

    while True:
        r, _, _ = select.select([dev.fd], [], [], 5.0)
        if not r:
            continue
        try:
            for ev in dev.read():
                if ev.type == e.EV_SW and ev.code == e.SW_LID:
                    set_closed(bl, ev.value == 1)
        except OSError:
            log("device disappeared, rescanning")
            dev = None
            while dev is None:
                dev = find_lid()
                time.sleep(2)
            log("using %s (%s)" % (dev.path, dev.name))


if __name__ == "__main__":
    main()
