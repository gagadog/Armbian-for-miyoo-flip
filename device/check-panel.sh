#!/bin/sh
echo "=== power_supply devices ==="
for d in /sys/class/power_supply/*; do
    [ -e "$d" ] || continue
    echo "--- $(basename "$d")"
    for f in type status capacity present voltage_now current_now online; do
        [ -f "$d/$f" ] && echo "    $f = $(cat "$d/$f" 2>/dev/null)"
    done
done
echo
echo "=== upower ==="
upower -e 2>/dev/null | head -10
upower -d 2>/dev/null | grep -E 'Device:|state:|percentage:|present:|time to' | head -20
echo
echo "=== audio ==="
ls /sys/class/sound/ 2>/dev/null
pactl info 2>&1 | head -6
echo
echo "=== xfce4-power-manager running? ==="
pgrep -a xfce4-power-manager || echo "  not running"
echo
echo "=== panel plugins (live) ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | head -30
echo "--- plugin types ---"
for i in $(seq 1 20); do
    t=$(DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins/plugin-$i/plugin 2>/dev/null)
    [ -n "$t" ] && echo "  plugin-$i = $t"
done
