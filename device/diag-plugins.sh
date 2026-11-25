#!/bin/sh
echo "=== panel plugin dirs ==="
for d in /usr/lib/*/xfce4/panel/plugins /usr/lib/xfce4/panel/plugins; do
    [ -d "$d" ] && { echo "--- $d"; ls "$d" | head -30; }
done

echo
echo "=== power manager plugin .so ==="
dpkg -L xfce4-power-manager 2>/dev/null | grep -E '\.so|plugins' | head -10
echo "--- pulseaudio plugin .so ---"
dpkg -L xfce4-pulseaudio-plugin 2>/dev/null | grep -E '\.so|plugins' | head -10

echo
echo "=== filesystem check ==="
ls -l /usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpowermanager.so 2>&1
ls -l /usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpulseaudio-plugin.so 2>&1

echo
echo "=== packages installed? ==="
dpkg -l xfce4-power-manager xfce4-pulseaudio-plugin 2>/dev/null | grep '^ii' | awk '{print "  "$2" "$3}'

echo
echo "=== panel log (last run) ==="
tail -20 /home/miyoo/panel-final.log 2>/dev/null
