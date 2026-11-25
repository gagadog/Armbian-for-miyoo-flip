#!/bin/sh
echo "=== hall device capabilities ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    caps = d.capabilities()
    if 5 in caps:          # EV_SW
        print(p, "->", d.name)
        print("   SW:", [evdev.ecodes.SW.get(c, c) for c in caps[5]])
PY
echo
echo "=== current lid state (SW_LID) ==="
for d in /sys/class/input/event*/device; do
    n=$(cat "$d/name" 2>/dev/null)
    case "$n" in *hall*) echo "  hall device: $(dirname $d)/$(basename $(dirname $d))";; esac
done
echo
echo "=== logind lid handling ==="
grep -iE 'HandleLidSwitch' /etc/systemd/logind.conf /etc/systemd/logind.conf.d/*.conf 2>/dev/null || echo "  (defaults: suspend)"
echo
echo "=== xfce4-power-manager lid settings ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-power-manager -l 2>/dev/null | grep -i lid || echo "  (none set)"
