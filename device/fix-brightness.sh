#!/bin/sh
echo "=== before ==="
cat /sys/class/backlight/backlight/brightness
echo "=== force 120 ==="
echo 120 > /sys/class/backlight/backlight/brightness
cat /sys/class/backlight/backlight/brightness

echo
echo "=== lid switch state ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    caps = d.capabilities()
    if 5 in caps and evdev.ecodes.SW_LID in caps[5]:
        print(" ", d.name, "active switches:", d.active_keys())
PY

echo
echo "=== miyoo-lid log / saved value ==="
ls -l /run/miyoo-lid.saved 2>/dev/null && cat /run/miyoo-lid.saved
pgrep -af miyoo-lid

echo
echo "=== what saved systemd-backlight state ==="
cat /var/lib/systemd/backlight/*backlight* 2>/dev/null | head -3
ls /var/lib/systemd/backlight/ 2>/dev/null | sed 's/^/  /'

echo
echo "=== xfpm brightness settings ==="
su - miyoo -c 'export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/brightness-switch 2>&1
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/brightness-switch-restore-on-exit 2>&1
'
